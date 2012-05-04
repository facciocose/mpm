require 'yaml'
require 'tempfile'

# config
ALGORITHM = 'AES256'
FILE = 'file.asc'
PASSWORD_SIZE = 12 

def generate_password(size = PASSWORD_SIZE)
  `pwgen -c -n -s -B #{size} 1`.strip
end

def open_editor(file)
  system(ENV['EDITOR'] + ' ' + file)
end

def copy_to_clipboard(string)
    IO.popen('pbcopy', 'w') do |pbcopy|
      pbcopy.write string
      pbcopy.close_write
    end
end

def help
  puts <<EOS
usage: mpm add <section> <key> <value>
       mpm get <section> <key>
       mpm del <section> [key]
       mpm password <section> [key]
       mpm list
EOS
  exit
end

def encrypt(input_file, output_file)
  system("gpg --quiet --batch --yes --armor --passphrase master --cipher-algo #{ALGORITHM} --output #{output_file} --symmetric #{input_file}")
end

def decrypt(input_file, output_file)
  system("gpg --quiet --no-use-agent --batch --yes --passphrase master --output #{output_file} #{input_file}")
end

def load_archive(archive_file)
  if File.exists?(archive_file)
    temp_file = Tempfile.new('mpm')
    temp_file.close
    decrypt(FILE, temp_file.path)

    data = ''
    File.open(temp_file.path, 'r') do |file|
      file.each_line do |line|
        data += line
     end
    end

    temp_file.delete

    archive = YAML::load(data)
  else
    archive = Hash.new
  end
end

def save_archive(archive_file, archive)
  temp_file = Tempfile.new('mpm')
  temp_file.puts archive.to_yaml 
  temp_file.close
  encrypt(temp_file.path, FILE)
  temp_file.delete
end

def add(section, key, value)
  archive = load_archive(FILE)

  if archive.include?(section)
    archive[section][key] = value
  else
    archive[section] = { key => value}
  end

  save_archive(FILE, archive)
end

def del(section, key = nil)
  archive = load_archive(FILE)

  if archive.include?(section)
    if key
      if archive[section].include?(key)
        archive[section].delete(key) 
        puts "deleted #{key} from #{section}"
      else
        puts "not found"
      end
      if archive[section].empty?
        archive.delete(section) 
        puts "deleted empty section #{section}"
      end
    else
      archive.delete(section)
        puts "deleted section #{section}"
    end
    save_archive(FILE, archive)
  else
    puts 'not found'
  end
end

def get(section, key)
  archive = load_archive(FILE)
  if archive.include?(section) and archive[section].include?(key)
    copy_to_clipboard(archive[section][key])
    puts 'data copied to clipboard'
  else
    puts 'not found'
  end
end

def password(section, key='password')
  key = 'password' if key.nil?
  temp_pass = generate_password
  add(section, key, temp_pass)
  copy_to_clipboard(temp_pass)
  puts "password generated for section #{section} and copied to clipboard"
end

def list
  archive = load_archive(FILE)

  if not archive.empty?
    puts archive.to_yaml
  end
end

def parse_options(opts)
  case opts
  when 'add'
    if ARGV.count == 4
      add(ARGV[1], ARGV[2], ARGV[3])
    else
      help
    end
  when 'del'
    if ARGV.count >= 2
      del(ARGV[1], ARGV[2])
    else
      help
    end
  when 'get'
    if ARGV.count == 3
      get(ARGV[1], ARGV[2])
    else
      help
    end
  when 'password'
    if ARGV.count >= 2
      password(ARGV[1], ARGV[2])
    else
      help
    end
  when 'list'
    list
  when 'edit'
    edit_file
  else
    help
  end
end

def edit_file
  temp_file = Tempfile.new('mpm')
  temp_file.close
  decrypt(FILE, temp_file.path)
  open_editor(temp_file.path)
  encrypt(temp_file.path, FILE) 
  temp_file.delete
end

if ARGV[0].nil?
  help
else
  parse_options(ARGV[0])
end
