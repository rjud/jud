require 'win32/registry'

module Jud::Library
  class RegistryError < RuntimeError    
  end
end

def reg_query path, name
  begin
    puts (Platform.blue "Read registry #{name} @ #{path}")
    Win32::Registry::HKEY_LOCAL_MACHINE.open(path) do |reg|
      _, data = reg.read(name)
      return data
    end
  rescue Win32::Registry::Error
    raise Jud::Library::RegistryError.new "Can't read registry key #{name} @ #{path}"
  else
    abort("[" << name << '] No value for reg query ' << path)
  end
end
