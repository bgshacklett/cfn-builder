package command

import (
	"github.com/bgshacklett/extropy/cfn"
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

	// bria0265-securitygroups

	/* TODO: Figure out update later
	result, err := updateStrategy.Execute(path, stackName, region)
	if err != nil {
		return err
	}

	_, err = fmt.Fprint(outputWriter, result)
	*/
	return nil
}
