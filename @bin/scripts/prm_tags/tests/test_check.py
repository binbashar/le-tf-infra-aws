"""Tests for the PRM aws-apn-id tag guardrail."""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import check  # noqa: E402


def _layer(tmp_path, rel, tf_files):
    """Create a layer directory with the given {filename: contents} files."""
    directory = tmp_path / rel
    directory.mkdir(parents=True)
    for name, body in tf_files.items():
        (directory / name).write_text(body, encoding="utf-8")
    return directory


TAGGED = 'locals {\n  tags = {\n    "aws-apn-id" = local.prm_apn_id\n  }\n}\n'
UNTAGGED = 'locals {\n  tags = {\n    Terraform = "true"\n  }\n}\n'


def test_layer_dirs_finds_only_dirs_with_config_tf(tmp_path):
    _layer(tmp_path, "shared/us-east-1/base-network", {"config.tf": "", "locals.tf": TAGGED})
    _layer(tmp_path, "shared/us-east-1/notalayer", {"locals.tf": TAGGED})
    assert sorted(check.layer_dirs(str(tmp_path))) == ["shared/us-east-1/base-network"]


def test_layer_dirs_skips_vendor_and_state_dirs(tmp_path):
    _layer(tmp_path, ".terraform/modules/x", {"config.tf": ""})
    _layer(tmp_path, "shared/us-east-1/base-network", {"config.tf": "", "locals.tf": TAGGED})
    assert sorted(check.layer_dirs(str(tmp_path))) == ["shared/us-east-1/base-network"]


def test_tagged_layer_passes(tmp_path):
    directory = _layer(tmp_path, "shared/us-east-1/a", {"config.tf": "", "locals.tf": TAGGED})
    assert check.has_prm_tag(str(directory)) is True


def test_untagged_layer_is_reported(tmp_path):
    directory = _layer(tmp_path, "shared/us-east-1/a", {"config.tf": "", "locals.tf": UNTAGGED})
    assert check.has_prm_tag(str(directory)) is False


def test_tag_found_when_it_lives_in_main_tf(tmp_path):
    # Two layers in this repo keep their tags map in main.tf, not locals.tf.
    directory = _layer(tmp_path, "a/b/c", {"config.tf": "", "main.tf": TAGGED})
    assert check.has_prm_tag(str(directory)) is True


def test_disabled_layers_are_checked_too(tmp_path):
    # All three disabled-suffix forms occur in this repo and every layer is
    # tagged, so none of them is exempt.
    for rel in ("a/us-east-1/x --", "a/us-east-1/y--", "a/us-east-1/z -- "):
        _layer(tmp_path, rel, {"config.tf": "", "locals.tf": UNTAGGED})
    assert check.main(["--root", str(tmp_path), "--allowlist", str(tmp_path / "none.txt")]) == 1


def test_allowlisted_layer_is_not_reported(tmp_path):
    _layer(tmp_path, "management/global/organizations", {"config.tf": "", "locals.tf": UNTAGGED})
    allowlist = tmp_path / "allow.txt"
    allowlist.write_text(
        "# creates only Organizations resources, none taggable\n"
        "management/global/organizations\n",
        encoding="utf-8",
    )
    assert check.main(["--root", str(tmp_path), "--allowlist", str(allowlist)]) == 0


def test_load_allowlist_strips_comments_and_blanks(tmp_path):
    allowlist = tmp_path / "allow.txt"
    allowlist.write_text("\n# a comment\n a/b/c  # trailing reason\n\n", encoding="utf-8")
    assert check.load_allowlist(str(allowlist)) == {"a/b/c"}


def test_clean_tree_exits_zero(tmp_path):
    _layer(tmp_path, "shared/us-east-1/a", {"config.tf": "", "locals.tf": TAGGED})
    assert check.main(["--root", str(tmp_path), "--allowlist", str(tmp_path / "none.txt")]) == 0


def test_symlinked_shared_file_does_not_count(tmp_path):
    # config/common-variables.tf is symlinked into 161 layers and mentions the
    # tag key in a comment, so following symlinks would make every layer pass.
    # A layer has to carry the tag in its own files.
    shared = tmp_path / "config"
    shared.mkdir()
    (shared / "common-variables.tf").write_text(
        "# `aws-apn-id = pc:<marketplace-product-code>` attributes consumption\n"
        "locals {}\n",
        encoding="utf-8",
    )
    directory = _layer(tmp_path, "shared/us-east-1/a", {"config.tf": "", "locals.tf": UNTAGGED})
    (directory / "common-variables.tf").symlink_to(shared / "common-variables.tf")
    assert check.has_prm_tag(str(directory)) is False
