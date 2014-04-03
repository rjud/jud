require 'tool'

class BuildTool < Tool
  
  Option = Struct.new(:desc, :type, :default, :cond)
  ResolvedOption = Struct.new(:name, :type, :enabled, :value)
  
  attr_reader :options
  
  def initialize
    super()
    @options = {}
  end
  
  def project sym
    if $conf.nil? then
      Object.const_get(sym.to_s).new
    else
      $conf.project sym
    end
  end
  
  def option id, type, desc: '', default: nil, cond: nil
    @options[id] = Option.new(desc, type, default, cond)
  end
  
  def resolve_options options
    ret = {}
    # Eval the default options of the application
    @options.each do |id, opt|
      if not opt.default.nil? and (opt.cond.nil? or options.key? opt.cond or ( ret.key? opt.cond and ret[opt.cond].value) ) then
        ret[id] = ResolvedOption.new(id.to_s, opt.type, true, opt.default.call)
      end
    end
    # Merge them with the given options
    options.each do |id, enabled|
      raise Error, "#{self.class.name}: unknown option '#{id.to_s}'" if not @options.key? id
      ret[id] = ResolvedOption.new(id.to_s, @options[id].type, enabled, enabled)
    end
    # Return the resolved options
    ret.values
  end
  
end
