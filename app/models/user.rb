class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :invitable, :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :confirmable

  # Setup accessible (or protected) attributes for your model
  # attr_accessible :email, :password, :password_confirmation, :remember_me

  validates_presence_of :username
  validates_uniqueness_of :jid, :if => Proc.new { jid.present? }
  
  has_many :activities
  has_many :relationships
  has_many :friends, :through => :relationships

  # def friends
  #   [
  #     Relationship.find(:all, :conditions => ["user_id=? and accepted = ?", id, true]).collect(&:friend),
  #     Relationship.find(:all, :conditions => ["friend_id=? and accepted = ?", id, true]).collect(&:user)
  #   ].flatten.uniq - [self]
  # end

  def username=(x)
    self.jid = "#{x}@#{Diaspora::Application.config.server_name}"
    super
  end
  
  def friend_requests
    Relationship.where(:friend_id => id, :accepted => false)
  end
  
  # end:conditions => {:}
  
  def gravatar
    "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest email}?d=mm"
  end

  def name
    if attributes['name'].present?
      attributes['name'] 
    elsif jid.present?
      jid.sub(/@.+/,'').capitalize
    elsif email.present?
      email.sub(/@.+/,'').capitalize
    else
      raise Exception, "Could not get a name for the user."
    end
  end

  def status
    if activities.any? and activities.first.content.present?
      activities.first.content.downcase
    else
      nil
    end
  end

  def invite!
    generate_invitation_token if self.invitation_token.nil?
    self.invitation_sent_at = Time.now.utc
    save(:validate => false)
    ::Devise.mailer.invitation(self).deliver
  end
  
  # @activities = Activity.find(:all, :order => 'created_at desc', :conditions => {:in_reply_to => nil, :type => 'status'}, :limit => 50)
  
  
  protected
  
  # def register_jabber_id
  #   "erl -setcookie `cat #{Rails::root}/config/erlang-cookie` -noinput -sname ejactl -pa /usr/lib/ejabberd/ebin -s ejabberd_ctl -extra ejabberd@`hostname` register #{username} #{Diaspora::Application.config.server_name} #{encrypted_password}"
  # end
  
end
