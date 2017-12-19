package command

import (
	"github.com/bgshacklett/extropy/cfn"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/aws"
	//awsHelper "github.com/bgshacklett/extropy/aws"
	"io"
	awsCloudformation "github.com/aws/aws-sdk-go/service/cloudformation"
	"fmt"
	"encoding/json"
	"github.com/awslabs/goformation/cloudformation"
)

// GetUpdatedTemplate handles the get-updated-template command.
func GetUpdatedTemplate(

	path string, // The path to the template
	stackName string, // The name of the associated stack
	region string, // The region where the associated stack resides
	outputWriter io.Writer, // The Writer for standard output
	updateStrategy cfn.TemplateUpdateStrategy, // Function to update the template

) error {

	//goCloudformatoin.ParseJSON

	// Create AWS session with region
	awsSession := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(region),
	}))

	// Create CFN service
	cfnService := awsCloudformation.New(awsSession)

	// Get CFN template output
	templateOutput, err := cfnService.GetTemplate(&awsCloudformation.GetTemplateInput{
		StackName: aws.String(stackName),
	})
	if err != nil {
		return err
	}
	// Create byte array out of template string
	originalTemplateBytes := []byte(*templateOutput.TemplateBody)

	// Unmarshal template into goformation.template type
	originalTemplateBody := &cloudformation.Template{}
	if err := json.Unmarshal(originalTemplateBytes, originalTemplateBody); err != nil {
		return err
	}

	res, err := originalTemplateBody.YAML()

	_, err = fmt.Fprint(outputWriter, string(res))
	//

	/* TODO: Figure out update later

	updateStrategy Params:
	(
	path string,
	stackName string,
	region string,
	original *cloudformation.Template,
	)

	result, err := updateStrategy(path, stackName, region)
	if err != nil {
		return err
	}

	_, err = fmt.Fprint(outputWriter, result)
	*/
	return nil
}
