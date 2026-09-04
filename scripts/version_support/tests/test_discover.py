import pytest

from version_support.discover import is_disabled_layer


@pytest.mark.parametrize(
    "path",
    [
        "apps-devstg/us-east-1/databases-mysql --",          # spaced form
        "apps-devstg/us-east-1/databases-dynamodb--",        # attached form
        "data-science/us-east-1/databases-aurora-mysql--",
        "apps-devstg/us-east-1/databases-mysql --/nested",   # disabled parent
    ],
)
def test_disabled_layers_are_detected(path):
    assert is_disabled_layer(path) is True


@pytest.mark.parametrize(
    "path",
    [
        "apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
        "apps-devstg/us-east-1/elasticache-redis",
        "management/global/organizations",
    ],
)
def test_active_layers_are_not_disabled(path):
    assert is_disabled_layer(path) is False


@pytest.mark.parametrize(
    ("path", "expected"),
    [
        ("", False),                                          # empty input
        ("/apps-devstg/us-east-1/databases-mysql --", True),  # absolute path
        ("apps-devstg/us-east-1/databases-mysql --/", True),  # trailing slash
        ("apps-devstg/us-east-1/databases-mysql -- ", True),  # trailing whitespace
        ("apps-devstg/us-east-1/foo--bar", False),            # -- mid-name is not a marker
    ],
)
def test_edge_cases_are_classified_correctly(path, expected):
    assert is_disabled_layer(path) is expected


import os

from version_support.discover import line_of, load_layer

FIXTURE_TREE = os.path.join(os.path.dirname(__file__), "fixtures", "tree")
EKS_LAYER = os.path.join(
    FIXTURE_TREE, "apps-devstg", "us-east-1", "k8s-eks-demoapps", "cluster"
)


def test_load_layer_strips_quotes_and_metadata():
    docs, errors = load_layer(EKS_LAYER)

    assert errors == []
    variables = docs[os.path.join(EKS_LAYER, "variables.tf")]["variable"]
    # python-hcl2 v8 would give '"cluster_version"' / '"1.31"' without our options.
    assert variables[0]["cluster_version"]["default"] == "1.31"
    assert "__comments__" not in docs[os.path.join(EKS_LAYER, "variables.tf")]


def test_line_of_finds_attribute_and_variable_block():
    assert line_of(os.path.join(EKS_LAYER, "main.tf"), "cluster_version") == 5
    assert line_of(os.path.join(EKS_LAYER, "variables.tf"), "cluster_version") == 1
    assert line_of(os.path.join(EKS_LAYER, "main.tf"), "nope") is None


from version_support.discover import Resolver

AURORA_LAYER = os.path.join(
    FIXTURE_TREE, "apps-devstg", "us-east-1", "databases-aurora-pgsql --"
)


def test_resolver_returns_literals_unchanged():
    resolver = Resolver({}, tfvars={})
    resolution = resolver.resolve("mysql")

    assert resolution.value == "mysql"
    assert resolution.how == "literal"


def test_resolver_dereferences_a_variable_default():
    docs, _ = load_layer(EKS_LAYER)
    resolver = Resolver(docs, tfvars={})

    resolution = resolver.resolve("${var.cluster_version}")

    assert resolution.value == "1.31"
    assert resolution.how == "var.cluster_version"
    assert resolution.origin.endswith("variables.tf")


def test_tfvars_override_beats_the_variable_default():
    docs, _ = load_layer(EKS_LAYER)
    resolver = Resolver(docs, tfvars={"cluster_version": "1.29"})

    resolution = resolver.resolve("${var.cluster_version}")

    # Reporting the default while a tfvars override supplies the real value
    # would be a false negative - the one failure this guardrail must not have.
    assert resolution.value == "1.29"
    assert resolution.how == "var.cluster_version (tfvars)"


def test_resolver_dereferences_a_local():
    docs, _ = load_layer(AURORA_LAYER)
    resolver = Resolver(docs, tfvars={})

    resolution = resolver.resolve("${local.engine}")

    assert resolution.value == "aurora-postgresql"
    assert resolution.how == "local.engine"


def test_unresolvable_reference_is_never_assumed_safe():
    resolver = Resolver({}, tfvars={})

    assert resolver.resolve("${var.missing}").how == "unresolved"
    assert resolver.resolve("${var.missing}").value is None
    assert resolver.resolve(None).how == "unresolved"
