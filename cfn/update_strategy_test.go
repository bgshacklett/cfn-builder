package cfn

import (
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/stretchr/testify"
	"testing"
)

func TestExecute(t *testing.T) {

	/*
	 * Test Cases
	 */
	testCases := []struct {
		path      string
		stackName string
		region    string
	}{
		{"path", "stackName", "region"},
	}

	for _, tc := range testCases {

		// Setup
		var updateStrategy TemplateUpdateStrategy = DefaultUpdateStrategy{}

		// Test
		result, err := updateStrategy.Execute(tc.path, tc.stackName, tc.region)

		// Teardown
	}
}
