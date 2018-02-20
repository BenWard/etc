require 'rubygems'
require 'rake'
require 'colored'

desc "Create symlinks for each of the files.  Prompts before overwriting"
task :symlink do
  create_symlinks
end

def all_files
  Dir.chdir("rootfiles") do
    Dir.glob('*')
  end
end

def ignore_files
  [ '.DS_Store', '.', '..' ]
end

def already_symlinked?(source_path, target_path)
  File.exists?(target_path) && File.lstat(target_path).symlink? && File.readlink(target_path) == source_path
end

def create_symlinks
  dir = File.dirname(__FILE__) + "/rootfiles/"

  (all_files - ignore_files).each do |file|
    homedir = File.expand_path ENV['HOME']
    source_path = File.join dir, file

    # Prepend dot for destination files
    target_path = File.join homedir, ".#{file}"
    unless already_symlinked?(source_path, target_path)
      if File.exists?(target_path)
        puts "File #{target_path} exists. Overwrite? (y/n)"
        if STDIN.gets.chomp.downcase == 'y'
          puts "#{"DELETED".red} #{target_path}"
          raise "This shouldn't happen, but if it does, I'm refusing to delete /" if target_path == "/"
          FileUtils.rm_r(target_path)
        else
          puts "#{"SKIPPED".blue} #{target_path}"
          next
        end
      else
        puts "File doesn't exist?"
      end

      puts "#{"LINKED".green} #{source_path} --> #{target_path.magenta}"
      FileUtils.ln_s(source_path, target_path)
    else
      puts "#{"EXISTS".green} #{source_path} --> #{target_path.magenta}"
    end
  end
end
