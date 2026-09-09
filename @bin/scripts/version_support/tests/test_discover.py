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


from version_support.discover import major_version


@pytest.mark.parametrize(
    ("engine", "version", "expected"),
    [
        ("mysql", "8.0.41", "8.0"),          # MySQL family keeps major.minor
        ("aurora-mysql", "5.7", "5.7"),
        ("aurora-mysql", "8.0.mysql_aurora.3.04.0", "8.0"),
        ("postgres", "14.18", "14"),         # PostgreSQL family keeps major only
        ("aurora-postgresql", "14.8", "14"),
        ("postgres", "16", "16"),
    ],
)
def test_major_version_is_engine_specific(engine, version, expected):
    assert major_version(engine, version) == expected


from version_support.discover import discover


def _by_layer(pins):
    return {pin.layer.replace(os.sep, "/"): pin for pin in pins}


def test_discover_finds_every_real_pin_shape():
    pins, errors = discover(FIXTURE_TREE)

    assert errors == []
    found = _by_layer(pins)
    assert set(found) == {
        "apps-devstg/us-east-1/k8s-eks-demoapps/cluster",
        "apps-devstg/us-east-1/databases-mysql --",
        "apps-devstg/us-east-1/databases-aurora-pgsql --",
        "shared/us-east-1/k8s-eks-v21/cluster",
    }


def test_discover_resolves_the_eks_variable_default():
    pins, _ = discover(FIXTURE_TREE)
    pin = _by_layer(pins)["apps-devstg/us-east-1/k8s-eks-demoapps/cluster"]

    assert pin.kind == "eks"
    assert pin.engine is None
    assert pin.version == "1.31"
    assert pin.active is True
    assert "var.cluster_version" in pin.source


def test_discover_resolves_the_aurora_engine_from_a_local():
    pins, _ = discover(FIXTURE_TREE)
    pin = _by_layer(pins)["apps-devstg/us-east-1/databases-aurora-pgsql --"]

    assert pin.kind == "rds"
    assert pin.engine == "aurora-postgresql"
    assert pin.version == "14.8"
    assert pin.major_version == "14"
    assert pin.active is False  # disabled layer


def test_discover_prefers_an_explicit_major_engine_version():
    pins, _ = discover(FIXTURE_TREE)
    pin = _by_layer(pins)["apps-devstg/us-east-1/databases-mysql --"]

    assert pin.engine == "mysql"
    assert pin.version == "8.0.41"
    assert pin.major_version == "8.0"


V21_LAYER = os.path.join(
    FIXTURE_TREE, "shared", "us-east-1", "k8s-eks-v21", "cluster"
)


def test_the_v21_kubernetes_version_argument_is_found():
    # terraform-aws-eks v21 renamed cluster_version -> kubernetes_version. Matching
    # only the old spelling made the EKS pin vanish silently when the module was
    # bumped: no error, just a report with no clusters in it.
    pins, _ = discover(FIXTURE_TREE)
    pin = _by_layer(pins)["shared/us-east-1/k8s-eks-v21/cluster"]

    assert pin.kind == "eks"
    assert pin.version == "1.33"
    assert "var.cluster_version" in pin.source


def test_a_data_block_named_kubernetes_version_is_not_a_pin(tmp_path):
    # data "aws_eks_addon_version" carries an identically named argument derived from
    # remote state. It is not a declaration and must not become a second pin -- the
    # real one lives in the cluster layer, which is scanned separately.
    layer = tmp_path / "apps-devstg" / "us-east-1" / "addons"
    layer.mkdir(parents=True)
    (layer / "addons.tf").write_text(
        'data "aws_eks_addon_version" "this" {\n'
        "  kubernetes_version = data.terraform_remote_state.cluster.outputs.cluster_version\n"
        "}\n"
    )

    pins, errors = discover(str(tmp_path))

    assert pins == []
    assert errors == []


def test_look_alikes_are_never_matched():
    pins, _ = discover(FIXTURE_TREE)
    layers = {pin.layer.replace(os.sep, "/") for pin in pins}

    # elasticache has engine_version but no engine; dms has a similarly-named key.
    assert "apps-devstg/us-east-1/elasticache-redis" not in layers
    assert "data-science/us-east-1/datalake--" not in layers


def test_malformed_tfvars_is_reported_not_swallowed(tmp_path):
    # A tfvars that hcl2 cannot parse must surface as an error, never degrade
    # silently to "no overrides" -- that would resolve pins to a stale default.
    (tmp_path / "config").mkdir()
    (tmp_path / "config" / "common.tfvars").write_text('project = "bb"\nbroken = {{{\n')
    layer = tmp_path / "apps-devstg" / "us-east-1" / "some-layer"
    layer.mkdir(parents=True)
    (layer / "main.tf").write_text(
        'module "x" {\n  engine         = "mysql"\n  engine_version = "8.0.41"\n}\n'
    )

    pins, errors = discover(str(tmp_path))

    assert len(pins) == 1
    assert any("common.tfvars" in e for e in errors)


def test_malformed_tfvars_is_reported_once_per_account_not_per_layer(tmp_path):
    # config/common.tfvars is consulted for every LAYER, and a real scan has 165
    # layers across 7 accounts. Without a per-account cache in discover(), a
    # single malformed common.tfvars is reported once per layer that shares the
    # account -- three byte-identical lines here, 165 in the real tree.
    (tmp_path / "config").mkdir()
    (tmp_path / "config" / "common.tfvars").write_text('project = "bb"\nbroken = {{{\n')
    for name in ("layer-one", "layer-two", "layer-three"):
        layer = tmp_path / "apps-devstg" / "us-east-1" / name
        layer.mkdir(parents=True)
        (layer / "main.tf").write_text(
            'module "x" {\n  engine         = "mysql"\n  engine_version = "8.0.41"\n}\n'
        )

    pins, errors = discover(str(tmp_path))

    assert len(pins) == 3  # all three layers were still scanned normally
    tfvars_errors = [e for e in errors if "common.tfvars" in e]
    assert len(tfvars_errors) == 1


@pytest.mark.parametrize(
    "skipped_dir",
    [".terraform", ".infracost", "docs"],
)
def test_vendored_and_docs_trees_are_never_scanned(tmp_path, skipped_dir):
    # A vendored module under .terraform/ really does carry a cluster_version block
    # in this repo; without the skip it would surface as an ACTIVE pin on a version
    # already in extended support, hard-failing every PR over an example file.
    nested = tmp_path / "apps-prd" / "global" / "x" / skipped_dir / "modules" / "eks"
    nested.mkdir(parents=True)
    (nested / "main.tf").write_text('module "eks" {\n  cluster_version = "1.28"\n}\n')

    pins, errors = discover(str(tmp_path))

    assert pins == []
    assert errors == []
