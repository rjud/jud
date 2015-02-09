require 'win32/registry'

def reg_query path, name
  begin
    Win32::Registry::HKEY_LOCAL_MACHINE.open(path) do |reg|
      type, data = reg.read(name)
      return data
    end
  else
    abort("[" << name << '] No value for reg query ' << path)
  end
end
