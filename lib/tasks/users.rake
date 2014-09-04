# ensure users path exists
def create_users_directory
  FileUtils.mkdir_p(File.join(ECMetal::Config.harness_dir, 'users'))
end
