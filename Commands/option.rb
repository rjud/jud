module Jud
  def self.option
    case ARGV.first
    when 'list'
      ARGV.shift
      claz = Object.const_get(ARGV.shift)
      claz.build_tool.options.each do | key, option |
        puts key, "\t" + (option[1].nil? ? 'No description' : option[1].to_s)
      end
    when 'add'
      ARGV.shift
      h = Jud::Config.instance.config
      paths = ARGV.shift.split('.')
      paths[0..-2].each { |p| h = h[p] }
      h[paths.last] = [] if not h.include? paths.last
      h[paths.last] << ARGV.shift
    when 'set'
      ARGV.shift
      h = Jud::Config.instance.config
      paths = ARGV.shift.split('.')
      paths[0..-2].each { |p| h = h[p] }
      h[paths.last] = ARGV.shift
    end
  end
end
