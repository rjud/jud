require 'win32/registry'

def reg_query path, name
  Win32::Registry::HKEY_LOCAL_MACHINE.open(path) do |reg|
    type, data = reg.read(name)
    return data
  end
  abort('No value for reg query ' << path << " /v " << name)
end
