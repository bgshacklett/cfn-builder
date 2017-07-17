# cfn-builder
Generates Cfn Template Code from Existing Resources

## Usage
1. Clone the repo to your preferred location
2. Source the `prototype.ps1` file to gain access to the functions
`> . ./prototype.ps1`
3. Ensure that you're logged into an AWS account via FAWS CLI or by copying the creds from the Janus page.
4. Clone the account's repo to your preferred location and change your working directory to match
5. Run the `Update-SecurityGroupTemplate` command, specifying the name of the Stack, path to the SG template and region. For example:
`> Update-SecurityGroupTemplate -Region us-east-1 -StackName SecurityGroup -Path ./SecurityGroup.template`
