require 'tool'

class BuildTool < Tool
  
  Option = Struct.new(:desc, :type, :default, :cond, :confcond)
  ResolvedOption = Struct.new(:name, :type, :enabled, :value, :confcond)
  
  attr_reader :options
  
  def initialize options = {}
    super()
    @options = options
  end
  
  def project sym
    Application.project sym
  end
  
  def option id, type, desc: '', default: nil, cond: nil, confcond: nil
    @options[id] = Option.new(desc, type, default, cond, confcond)
  end
  
  def depends prj
    [].tap do |depends|
      @options.each do |id, opt|
        depends.concat (prj.auto_depends opt.default, opt.cond)
      end
    end
  end
  
  def resolve_options context, options
    ret = {}
    # Eval the default options of the project
    @options.each do |id, opt|
      if not opt.default.nil? and (opt.cond.nil? or options.key? opt.cond or ( ret.key? opt.cond and ret[opt.cond].value) ) then
        if opt.confcond.nil? or context.instance_eval &opt.confcond
          puts "#{id} #{context.eval_option opt.default}"
          ret[id] = ResolvedOption.new id.to_s, opt.type, true, (context.eval_option opt.default), opt.confcond
        end
      end
    end
    # Merge them with the given options
    options.each do |id, enabled|
      raise Error, "#{self.class.name}: unknown option '#{id.to_s}'" if not @options.key? id
      ret[id] = ResolvedOption.new(id.to_s, @options[id].type, enabled, enabled, @options[id].confcond)
    end
    # Return the resolved options
    ret.values
  end
  
end
