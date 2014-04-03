# ensure users path exists
def create_users_directory
  FileUtils.mkdir_p(File.join(ENV['HARNESS_DIR'], 'users'))
end
