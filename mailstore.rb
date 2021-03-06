require 'pstore'
require 'ostruct'
require 'openssl'

class Mail < OpenStruct
end
class Database
  def initialize
    @store = PStore.new("mail_storage")
  end
  def mail(user)
    mail = nil
    @store.transaction do
      mail = @store["mail:#{user}"]
    end
    return nil if mail.nil?
    return mail.map do |message|
      { :from => message.from, :message => message.message, :time => message.time }
    end
  end
  def store(options)
    @store.transaction do
      @store["mail:#{options[:user]}"] ||= []
      mail = Mail.new
      mail.from = options[:from]
      mail.message = options[:message]
      mail.time = options[:time]
      @store["mail:#{options[:user]}"] << mail
    end
  end
  def add_host(host, modulus)
    @store.transaction do
      @store['tap'] ||= [ {"is"=> modulus.to_s.sha1}, {"has" => ["+body"] }, { "is" => modulus.to_s.sha1, "has" => "+newhost"} ]
      @store['hosts'] ||= []
      @store['hosts'] << host
      @store['tap'] += [{"is" => host }]
      @store['tap'].uniq!
    end
  end
  def hosts
    @store.transaction do
      return @store['hosts']
    end
  end
  def modulus
    mod = nil
    @store.transaction do
      mod = @store['n']
      if mod.nil?
        p "creating modulus"
        key = OpenSSL::PKey::RSA.new(128)
        @store['n'] = key.n.to_i
        @store['e'] = key.e.to_i
        mod = @store['n']
      end
    end
    return mod
  end
  def tap(modulus)
    tap = nil
    @store.transaction do
      @store['tap'] ||= [ {"is"=> modulus.to_s.sha1}, {"has" => ["+body"] }, { "is" => modulus.to_s.sha1, "has" => "+newhost"} ]
      tap = {".tap" => @store['tap'] }
    end
    return tap
  end
end
