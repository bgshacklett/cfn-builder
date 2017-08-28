package command

import (
	"extropy/cfn"
	"fmt"
	"io"
)

// GetUpdatedTemplate handles the get-updated-template command.
func GetUpdatedTemplate(

	path string, // The path to the template
	stackName string, // The name of the associated stack
	region string, // The region where the associated stack resides
	outputWriter io.Writer, // The Writer for standard output
	updateStrategy cfn.TemplateUpdateStrategy, // Function to update the template

) error {

	result, err := updateStrategy(path, stackName, region)
	if err != nil {
		return err
	}

	_, err = fmt.Fprint(outputWriter, result)
	return err
}
