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
