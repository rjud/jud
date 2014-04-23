require 'pack_tool'

require 'rubygems/package'
require 'zlib'

class Tarball < PackTool
  
  class << self
    def load_path; false; end
  end
  
  Tarball.configure
  
  def initialize
    super('tar.gz')
  end
  
  def pack_impl filename, directory
    
    tarname = File.basename filename, (File.extname filename)
    tarfile = File.new tarname, 'wb'
    
    Gem::Package::TarWriter.new(tarfile) do |tar|
      Dir[File.join directory, '**/*'].each do |file|
        mode = File.stat(file).mode
        relative = file.sub /^#{Regexp::escape directory}\/?/, ''
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
    Gem::Package::TarReader.new(Zlib::GzipReader.open filename) do |tar|
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
        elsif entry.file?
          File.open dest, "wb" do |f|
            f.print entry.read
          end
          FileUtils.chmod entry.header.mode, dest, :verbose => false
        elsif entry.header.typeflag == '2'
          File.symlink entry.header.linkname, dest
        end
        dest = nil
      end
    end
  end
  
end
