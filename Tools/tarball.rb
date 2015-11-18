require 'pack_tool'

require 'rubygems/package'
require 'zlib'

class File    
  MEGABYTE ||= 1024 * 1024
  def each_chunk chunk_size=MEGABYTE
    yield (read chunk_size) until eof?
  end
end

module Jud::Tools
  class Tarball < PackTool
    
    class << self
      def pure_ruby; true; end
    end
    
    def initialize ext='tar.gz', config={}
      super ext, config
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
      
      File.open filename, 'wb' do |zipfile|
        zip = Zlib::GzipWriter.new zipfile
        open tarname, "rb" do |tarfile|
          tarfile.each_chunk do |chunk|
            zip.write chunk
          end
        end
        zip.close
      end
      
      File.delete tarname
      
    end
    
    def unpack filename, destination
      puts (Platform.blue "Unpacking #{filename} to #{destination}")
      io = 
        begin
          Zlib::GzipReader.open filename
        rescue Zlib::GzipFile::Error => e
          puts (Platform.red "Can't open #{filename}")
          puts (Platform.red e)
          puts (Platform.red "Open it as an uncompressed file")
          File.open filename
        end
      Gem::Package::TarReader.new io do |tar|
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
            Dir.chdir Pathname(dest).dirname
            linkname = Pathname(dest).basename
            FileUtils.rm linkname if File.exist? linkname
            File.symlink entry.header.linkname, linkname
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
end
