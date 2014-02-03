require 'pack_tool'

require 'zip'

class ZipTool < PackTool
    
  def initialize name
    super(name, false, 'zip')
  end
  
  def pack_impl filename, directory
    Zip::ZipFile.open(filename.to_s, Zip::ZipFile::CREATE) do |zipfile|
      Dir[directory.join('**', '**')].each do |file|
        zipfile.add(file.sub(directory.to_s + '/', ''), file)
      end
    end
  end
  
  def unpack filename, destination
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
