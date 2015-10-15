require 'pack_tool'

require 'rubygems/package'
require 'zlib'

class Tarball < PackTool
  
  class << self
    def load_path; false; end
  end
  
  def initialize ext='tar.gz'
    super(ext)
  end
  
  def pack_impl filename, directory
    
    tarname = File.basename filename, (File.extname filename)
    tarfile = File.new tarname, 'wb'
    
    Gem::Package::TarWriter.new(tarfile) do |tar|
      Dir[File.join directory, '**/*'].each do |file|
        mode = File.stat(file).mode
        relative = file.sub /^#{Regexp::escape directory.to_s}\/?/, ''
        if File.directory? file
          tar.mkdir relative, mode
        else
          tar.add_file relative, mode do |tarf|
            File.open file, 'rb' do
              |f| tarf.write f.read
            end
          end
        end
      end
    end
    
    tarfile.close
    
    tarfile = File.new tarname, 'rb'
    zip = Zlib::GzipWriter.new(File.new filename, 'wb')
    zip.write tarfile.read
    tarfile.close
    zip.close
    
    File.delete tarname
    
  end
  
  def unpack filename, destination
    io = 
      begin
        Zlib::GzipReader.open filename
      rescue Zlib::GzipFile::Error => e
        puts (Platform.red e)
        File.open filename
      end
    puts (Platform.blue "Unpacking #{filename} to #{destination}")
    Gem::Package::TarReader.new (Zlib::GzipReader.open filename.to_s) do |tar|
      dest = nil
      tar.each do |entry|
        if entry.full_name == '././@LongLink'
          dest = File.join destination, entry.read.strip
          next
        end
        dest ||= File.join destination, entry.full_name
        if File.exist? dest then
          Platform.red(dest.to_s + ' already existing')
        end
        if entry.directory?
          FileUtils.mkdir_p dest, :mode => entry.header.mode, :verbose => false
        elsif entry.header.typeflag == '2'
          old_name = dest
          new_name = File.join destination, entry.header.linkname
          File.symlink old_name, new_name if not File.symlink? new_name
        else
          # Sometimes, the TarReader library doesn't consider that a file is a file ???
          puts (Platform.red "#{entry.full_name} doesn't seem to be a file") if not entry.file?
          dirname = Pathname(dest).dirname
          FileUtils.mkdir_p dirname, :verbose => false if not File.exist? dirname
          File.open dest, "wb" do |f|
            f.print entry.read
          end
          FileUtils.chmod entry.header.mode, dest, :verbose => false
        end
        dest = nil
      end
    end
  end
  
end
