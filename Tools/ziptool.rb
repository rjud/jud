require 'pack_tool'

module Jud::Tools
  class ZipTool < PackTool
    
    class << self
      def pure_ruby; true; end
    end
    
    def initialize ext='.zip', config={}
      super ext, config
    end
    
    def pack_impl filename, directory
      require 'zip'
      File.delete filename if File.exists? filename
      Zip::ZipFile.open(filename.to_s, Zip::ZipFile::CREATE) do |zipfile|
        Dir[directory.join('**', '**')].each do |filename|
          if File.directory? filename
            zipfile.mkdir filename.sub(directory.to_s + '/', '')
          else
            zipfile.get_output_stream filename.sub(directory.to_s + '/', '') do |out|
              out.write File.binread filename
            end
          end
        end
      end
    end
    
    def unpack filename, destination
      require 'zip'
      Zip::ZipFile.open(filename.to_s) do |zip_file|
        zip_file.each do |file|
          file_path = destination.join(file.name)
          FileUtils.mkdir_p file_path.dirname
          if file_path.exist? then
            Platform.red(file_path.to_s + ' already existing') 
          else
            zip_file.extract file, file_path
          end
        end
      end
    end
    
  end
end
