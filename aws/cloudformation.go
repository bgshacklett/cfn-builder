package aws

import (
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/cloudformation"
)

// GetStackTemplateBody retrieves template used in live stack
func GetStackTemplateBody(region string, stackName string) (*string ,error) {

	// Create AWS session with region
	awsSession := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(region),
	}))

	// Create CFN service
	cfnService := cloudformation.New(awsSession)

	// Get CFN template output
	templateOutput, err := cfnService.GetTemplate(&cloudformation.GetTemplateInput{
		StackName: aws.String(stackName),
	})
	if err != nil {
		return nil, err
	}
	return templateOutput.TemplateBody, nil
}

func GetStackResources(region string, stackName string) (*cloudformation.DescribeStackResourcesOutput, error) {

	// Create AWS session with region
	awsSession := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(region),
	}))

	// Create CFN service
	cfnService := cloudformation.New(awsSession)

	// Get all stack resources
	resourcesOutput, err := cfnService.DescribeStackResources(&cloudformation.DescribeStackResourcesInput{
		StackName: aws.String(stackName),
	})
	if err != nil {
		return nil, err
	}

	return resourcesOutput, nil

}


