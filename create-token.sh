#!/bin/bash
# GitLab Personal Access Token Creator
# Usage: ./create-token.sh [token-name] [days-until-expiry]

TOKEN_NAME=${1:-"api-token-$(date +%s)"}
DAYS=${2:-365}
USERNAME=${3:-"root"}

echo "Creating GitLab Personal Access Token..."
echo "User: $USERNAME"
echo "Token Name: $TOKEN_NAME"
echo "Valid for: $DAYS days"
echo ""

docker exec gitlab gitlab-rails runner "
user = User.find_by_username('$USERNAME')
if user.nil?
  puts 'ERROR: User not found!'
  exit 1
end

token = user.personal_access_tokens.create!(
  name: '$TOKEN_NAME',
  scopes: [ :api, :read_user, :read_repository, :write_repository, :read_api, :sudo ],
  expires_at: Date.today + $DAYS
)

puts '=' * 70
puts 'SUCCESS! Personal Access Token Created'
puts '=' * 70
puts 'Token: ' + token.token
puts 'Name: ' + token.name
puts 'User: $USERNAME'
puts 'Scopes: ' + token.scopes.join(', ')
puts 'Created: ' + token.created_at.to_s
puts 'Expires: ' + token.expires_at.to_s
puts '=' * 70
puts ''
puts '⚠️  IMPORTANT: Copy this token NOW! You wont see it again.'
puts ''
"

