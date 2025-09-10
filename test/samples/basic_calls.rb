# Sample file for testing various method call patterns

# Class method calls
User.find(1)
User.where(active: true)
Post.published

# Instance method calls via local variables
user = User.new
user.name
user.email

# Instance method calls via instance variables
@post = Post.new
@post.title
@post.content

# Self calls
class Article
  def update_status
    self.status = "published"
    self.save
  end
end

# No receiver calls (implicit self)
class Book
  def validate_title
    validate :title, presence: true
    before_save :normalize_title
    helper_method :formatted_title
  end
end

# Method chaining
User.active.where(role: "admin").limit(10)

# Each and other iterators
users.each { |u| u.active? }
[1, 2, 3].map { |n| n * 2 }