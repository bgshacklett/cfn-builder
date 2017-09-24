package cfn

import (
	"github.com/awslabs/goformation/cloudformation"
	"github.com/stretchr/testify"
	"testing"
)

func TestExecute(t *testing.T) {

	/*
	 * Test Cases
	 */
	testCases := []struct {
		template  cloudformation.Template
		stackName string
		region    string
	}{
		{new(cloudformation.Template), "stackName", "region"},
	}

	for _, tc := range testCases {

		// Setup
		var updateStrategy TemplateUpdateStrategy = new(DefaultUpdateStrategy)

		// Test
		result, err := updateStrategy.Execute(tc.path, tc.stackName, tc.region)

		// Teardown
	}
}
