def test_dependencies_import():
    import boto3
    import hcl2
    from hcl2.utils import SerializationOptions

    assert SerializationOptions().strip_string_quotes is False
