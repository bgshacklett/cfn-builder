package aws

import (
	goCloudformation "github.com/awslabs/goformation/cloudformation"
	"encoding/json"
)

// GetGoformationTemplate unmarshals template body into gofmormation type
func GetGoformationTemplate(region string, stackName string) (*goCloudformation.Template, error) {

	template,err := GetStackTemplateBody(region, stackName)
	if err != nil {
		return nil, err
	}
	// Create byte array out of template string
	originalTemplateBytes := []byte(*template)

	// Unmarshal template into goformation.template type
	originalTemplateBody := &goCloudformation.Template{}
	if err := json.Unmarshal(originalTemplateBytes, originalTemplateBody); err != nil {
		return nil, err
	}
	return originalTemplateBody, nil
}

