require 'Tool'

class BuildTool < Tool
  
  Option = Struct.new(:desc, :type, :default, :cond)
  ResolvedOption = Struct.new(:name, :type, :enabled, :value)
  
  attr_reader :options
  
  def initialize
    super()
    @options = {}
  end
  
  def option id, type, desc: '', default: nil, cond: nil
    @options[id] = Option.new(desc, type, default, cond)
  end
  
  def resolve_options options
    ret = []
    @options.each do |id, opt|
      if opt.default and (opt.cond.nil? or options.key? opt.cond) then
        ret << ResolvedOption.new(id.to_s, opt.type, true, opt.default.call)
      end
    end
    options.each do |id, enabled|
      abort 'Unknown option ' + id.to_s if not @options.key? id
      ret <<  ResolvedOption.new(id.to_s, @options[id].type, enabled, enabled)
    end
    ret
  end
  
end
