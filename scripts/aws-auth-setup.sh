#!/bin/bash

# AWS CLI Authentication Setup Script with Two-Factor Authentication
# This script helps set up AWS CLI with MFA/2FA support

set -e

echo "🔐 AWS CLI Authentication Setup with Two-Factor Authentication"
echo "=============================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Check if AWS CLI is installed
check_aws_cli() {
    print_header "Checking AWS CLI installation..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first:"
        echo "  macOS: brew install awscli"
        echo "  Ubuntu: sudo apt-get install awscli"
        echo "  Or download from: https://aws.amazon.com/cli/"
        exit 1
    fi
    
    aws_version=$(aws --version)
    print_status "AWS CLI found: $aws_version"
}

# Configure AWS credentials
configure_aws_credentials() {
    print_header "Configuring AWS credentials..."
    
    echo ""
    echo "Please provide your AWS credentials:"
    echo "-----------------------------------"
    
    read -p "AWS Access Key ID: " aws_access_key_id
    read -s -p "AWS Secret Access Key: " aws_secret_access_key
    echo ""
    read -p "Default region (e.g., us-west-2): " aws_region
    read -p "Default output format (json): " aws_output_format
    
    # Set defaults if empty
    aws_output_format=${aws_output_format:-json}
    
    # Configure AWS CLI
    aws configure set aws_access_key_id "$aws_access_key_id"
    aws configure set aws_secret_access_key "$aws_secret_access_key"
    aws configure set default.region "$aws_region"
    aws configure set default.output "$aws_output_format"
    
    print_status "AWS credentials configured successfully"
}

# Set up MFA profile
setup_mfa_profile() {
    print_header "Setting up MFA profile..."
    
    echo ""
    echo "MFA Configuration:"
    echo "-----------------"
    
    read -p "MFA device ARN (arn:aws:iam::ACCOUNT:mfa/USERNAME): " mfa_device_arn
    read -p "Profile name for MFA (default: mfa): " mfa_profile_name
    
    # Set default profile name
    mfa_profile_name=${mfa_profile_name:-mfa}
    
    # Create MFA profile configuration
    cat >> ~/.aws/config << EOF

[profile $mfa_profile_name]
region = $(aws configure get default.region)
output = $(aws configure get default.output)
role_arn = arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/OrganizationAccountAccessRole
source_profile = default
mfa_serial = $mfa_device_arn
EOF
    
    print_status "MFA profile '$mfa_profile_name' configured"
    print_warning "You'll need to assume the role manually or use aws-vault for automatic MFA"
}

# Create MFA token script
create_mfa_script() {
    print_header "Creating MFA token helper script..."
    
    cat > scripts/get-mfa-token.sh << 'EOF'
#!/bin/bash

# MFA Token Helper Script
# This script prompts for MFA token and returns temporary credentials

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔐 AWS MFA Token Helper${NC}"
echo "=========================="

# Get MFA device ARN from config
mfa_device_arn=$(aws configure get mfa_serial --profile mfa 2>/dev/null || echo "")

if [ -z "$mfa_device_arn" ]; then
    read -p "Enter MFA device ARN: " mfa_device_arn
fi

# Prompt for MFA token
read -p "Enter MFA token (6 digits): " mfa_token

# Validate token format
if [[ ! $mfa_token =~ ^[0-9]{6}$ ]]; then
    echo -e "${RED}Error: MFA token must be 6 digits${NC}"
    exit 1
fi

# Get temporary credentials
echo "Getting temporary credentials..."
temp_creds=$(aws sts get-session-token \
    --serial-number "$mfa_device_arn" \
    --token-code "$mfa_token" \
    --output json)

# Extract credentials
access_key=$(echo "$temp_creds" | jq -r '.Credentials.AccessKeyId')
secret_key=$(echo "$temp_creds" | jq -r '.Credentials.SecretAccessKey')
session_token=$(echo "$temp_creds" | jq -r '.Credentials.SessionToken')
expiration=$(echo "$temp_creds" | jq -r '.Credentials.Expiration')

# Set environment variables
export AWS_ACCESS_KEY_ID="$access_key"
export AWS_SECRET_ACCESS_KEY="$secret_key"
export AWS_SESSION_TOKEN="$session_token"

echo -e "${GREEN}✅ Temporary credentials obtained${NC}"
echo "Expiration: $expiration"
echo ""
echo "To use these credentials in your current shell:"
echo "source scripts/get-mfa-token.sh"
echo ""
echo "Or set them manually:"
echo "export AWS_ACCESS_KEY_ID=\"$access_key\""
echo "export AWS_SECRET_ACCESS_KEY=\"$secret_key\""
echo "export AWS_SESSION_TOKEN=\"$session_token\""
EOF
    
    chmod +x scripts/get-mfa-token.sh
    print_status "MFA token helper script created: scripts/get-mfa-token.sh"
}

# Create Terraform profile configuration
setup_terraform_profile() {
    print_header "Setting up Terraform AWS profile..."
    
    read -p "Terraform profile name (default: runic-dev): " tf_profile_name
    tf_profile_name=${tf_profile_name:-runic-dev}
    
    # Create Terraform-specific profile
    cat >> ~/.aws/config << EOF

[profile $tf_profile_name]
region = $(aws configure get default.region)
output = $(aws configure get default.output)
role_arn = arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/OrganizationAccountAccessRole
source_profile = default
mfa_serial = $(aws configure get mfa_serial --profile mfa 2>/dev/null || echo "")
EOF
    
    print_status "Terraform profile '$tf_profile_name' configured"
}

# Test AWS configuration
test_aws_config() {
    print_header "Testing AWS configuration..."
    
    echo "Testing default profile..."
    if aws sts get-caller-identity &> /dev/null; then
        print_status "Default profile working correctly"
        aws sts get-caller-identity
    else
        print_error "Default profile test failed"
        return 1
    fi
    
    echo ""
    echo "Testing MFA profile..."
    if aws sts get-caller-identity --profile mfa &> /dev/null; then
        print_status "MFA profile working correctly"
    else
        print_warning "MFA profile test failed - you may need to assume the role manually"
    fi
}

# Create usage instructions
create_usage_instructions() {
    print_header "Creating usage instructions..."
    
    cat > scripts/aws-usage.md << EOF
# AWS CLI Usage with MFA

## Quick Start

1. **Get MFA Token**:
   \`\`\`bash
   source scripts/get-mfa-token.sh
   \`\`\`

2. **Use with Terraform**:
   \`\`\`bash
   export AWS_PROFILE=runic-dev
   cd terraform/envs/dev
   terraform init
   terraform plan
   \`\`\`

3. **Use with AWS CLI**:
   \`\`\`bash
   aws s3 ls --profile mfa
   \`\`\`

## Profiles Available

- **default**: Basic AWS credentials
- **mfa**: MFA-enabled profile
- **runic-dev**: Terraform development profile

## Environment Variables

When using MFA, set these environment variables:
\`\`\`bash
export AWS_ACCESS_KEY_ID="your-temp-access-key"
export AWS_SECRET_ACCESS_KEY="your-temp-secret-key"
export AWS_SESSION_TOKEN="your-temp-session-token"
\`\`\`

## Troubleshooting

- **MFA Token Expired**: Run the MFA script again
- **Permission Denied**: Check your IAM permissions
- **Profile Not Found**: Verify ~/.aws/config exists

## Security Notes

- Never commit AWS credentials to version control
- Rotate access keys regularly
- Use least privilege IAM policies
- Enable CloudTrail for audit logging
EOF
    
    print_status "Usage instructions created: scripts/aws-usage.md"
}

# Main execution
main() {
    echo "🔐 AWS CLI Authentication Setup with Two-Factor Authentication"
    echo "=============================================================="
    echo ""
    
    check_aws_cli
    configure_aws_credentials
    setup_mfa_profile
    create_mfa_script
    setup_terraform_profile
    test_aws_config
    create_usage_instructions
    
    echo ""
    echo "🎉 AWS CLI setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Review scripts/aws-usage.md for usage instructions"
    echo "2. Test MFA: source scripts/get-mfa-token.sh"
    echo "3. Use with Terraform: export AWS_PROFILE=runic-dev"
    echo ""
    echo "For Terraform usage, update terraform/envs/dev/config.tfvars:"
    echo "aws_profile = \"runic-dev\""
    echo "aws_region = \"$(aws configure get default.region)\""
}

# Run main function
main "$@"


