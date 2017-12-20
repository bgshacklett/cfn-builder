package command

import (
	"github.com/bgshacklett/extropy/cfn"
	"io"
	"github.com/bgshacklett/extropy/aws"
	"fmt"
)

// GetUpdatedTemplate handles the get-updated-template command.
func GetUpdatedTemplate(

	path string, // The path to the template
	stackName string, // The name of the associated stack
	region string, // The region where the associated stack resides
	outputWriter io.Writer, // The Writer for standard output
	updateStrategy cfn.TemplateUpdateStrategy, // Function to update the template

) error {


	// get template for stack
	originalTemplate, err := aws.GetGoformationTemplate(region, stackName)
	if err != nil {
		return err
	}

	// get list of supported resources from all stack resources
	supportedResources, err := aws.GetSupportedResources(region, stackName)
	if err != nil {
		return err
	}

	// get generated template from goformation
	updatedTemplate,err := cfn.BuildTemplate(*supportedResources, region)
	if err != nil {
		return nil
	}
	j,err := updatedTemplate.JSON()
	fmt.Println(string(j))
	fmt.Sprint(originalTemplate)

	/* TODO: Figure out update

	updateStrategy Params:
	(
	path string, - UNUSED
	stackName string,
	region string,
	original *cloudformation.Template,
	updatedTemplate *cloudformation.Template,
	)
	*/
	/*
	result, err := updateStrategy(stackName, region, supportedResources, originalTemplate, updatedTemplate)
	if err != nil {
		return err
	}

	_, err = fmt.Fprint(outputWriter, result)
	*/

	return nil
}
