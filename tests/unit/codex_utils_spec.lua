-- luacheck: globals expect
require("tests.busted_setup")

describe("codex.utils prepare_job_env", function()
  local utils

  before_each(function()
    package.loaded["codex.utils"] = nil
    utils = require("codex.utils")
  end)

  it("returns nil for nil or non-table", function()
    expect(utils.prepare_job_env(nil)).to_be_nil()
    expect(utils.prepare_job_env("x")).to_be_nil()
  end)

  it("returns nil for empty table (omit env from jobstart)", function()
    expect(utils.prepare_job_env({})).to_be_nil()
  end)

  it("merges string vars onto environ()", function()
    local merged = utils.prepare_job_env({ CODEX_TEST = "1" })
    expect(merged).to_be_table()
    assert.are.equal("/usr/bin", merged.PATH)
    assert.are.equal("/home/user", merged.HOME)
    assert.are.equal("1", merged.CODEX_TEST)
  end)

  it("coerces non-string values to string", function()
    local merged = utils.prepare_job_env({ N = 42 })
    assert.are.equal("42", merged.N)
  end)

  it("ignores empty or non-string keys", function()
    local merged = utils.prepare_job_env({ [""] = "bad", good = "yes" })
    assert.is_nil(merged[""])
    assert.are.equal("yes", merged.good)
  end)
end)
