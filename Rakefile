# encoding: utf-8

task :build => :update do
	Rake::Task['clean'].execute
	puts "[*] Building msfrpc-client.gemspec"
	system "gem build msfrpc-client.gemspec &> /dev/null"
end

task :release => :build do
	puts "[*] Pushing msfrpc-client to rubygems.org"
	system "gem push msfrpc-client-*.gem &> /dev/null"
	Rake::Task['clean'].execute
end

task :clean do
	system "rm *.gem &> /dev/null"
end

