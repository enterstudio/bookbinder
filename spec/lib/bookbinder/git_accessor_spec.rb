require 'pathname'
require 'tmpdir'
require_relative '../../helpers/git_repo'
require_relative '../../../lib/bookbinder/git_accessor'

module Bookbinder
  describe GitAccessor do
    include GitRepo

    it "clones to a given dir" do
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        init_repo(at_dir: path.join('srcgorepo'),
                  file: 'foo',
                  contents: 'bar',
                  commit_message: 'baz')
        GitAccessor.new.clone(path.join("srcgorepo"), 'destgorepo', path: path)
        expect(path.join('destgorepo', 'foo').read).to eq("bar\n")
      end
    end

    it "only clones once for a given set of params" do
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        init_repo(at_dir: path.join('srcrepo'),
                  file: 'Gemfile',
                  contents: 'gemstuffz',
                  commit_message: 'new railz plz')

        git = GitAccessor.new

        git.clone(path.join('srcrepo'), 'destrepo', path: path)
        expect { git.clone(path.join('srcrepo'), 'destrepo', path: path) }.
          not_to change { path.join('destrepo', 'Gemfile').mtime }
      end
    end

    it "can clone and checkout in one call" do
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        init_repo(branch: 'mybranch',
                  at_dir: path.join('srcgorepo'),
                  file: 'foo',
                  contents: 'bar',
                  commit_message: 'baz')
        GitAccessor.new.clone(path.join("srcgorepo"), 'destgorepo',
                              checkout: 'mybranch',
                              path: path)
        expect(path.join('destgorepo', 'foo').read).to eq("bar\n")
      end
    end

    it "can checkout different branches of the same cached repo" do
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        init_repo(at_dir: path.join('srcrepo'),
                  file: 'Gemfile',
                  contents: 'gemstuffz',
                  commit_message: 'new railz plz',
                  branch: 'newbranch')

        git = GitAccessor.new

        git.clone(path.join('srcrepo'), 'destrepo', path: path, checkout: 'newbranch')
        expect(path.join('destrepo/Gemfile')).to exist
        git.clone(path.join('srcrepo'), 'destrepo', path: path, checkout: 'master')
        expect(path.join('destrepo/Gemfile')).not_to exist
      end
    end

    it "can return the contents of a file in one step, using its own temp directory" do
      Dir.mktmpdir do |dir|
        path = Pathname(dir)
        init_repo(at_dir: path.join('srcrepo'),
                  file: 'Gemfile',
                  contents: 'gemstuffz',
                  commit_message: 'new railz plz',
                  branch: 'newbranch')

        git = GitAccessor.new

        expect(
          git.read_file(
            "Gemfile",
            from_repo: path.join('srcrepo'),
            checkout: 'newbranch'
          )
        ).to eq("gemstuffz\n")
      end
    end
  end
end
