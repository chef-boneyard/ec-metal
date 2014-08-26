remote_file "/tmp/packages@opscode.com.gpg.key" do
  source "http://apt.opscode.com/packages@opscode.com.gpg.key"
end

execute "rpm --import /tmp/packages\@opscode.com.gpg.key"
