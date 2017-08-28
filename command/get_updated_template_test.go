package command

import (
	"bytes"
	"extropy/cfn"
	"fmt"
	"github.com/stretchr/testify/assert"
	"io/ioutil"
	"strings"
	"testing"
)

var testUpdateStrategy cfn.TemplateUpdateStrategy = func(

	path string,
	stackName string,
	region string,

) (interface{}, error) {

	return strings.Join([]string{path, stackName, region}, ","), nil
}

// TestUpdateTemplate is a Unit Test for the UpdateTemplate function.
func TestGetUpdatedTemplate(t *testing.T) {

	testCases := []struct {
		path      string
		stackName string
		region    string
		expected  string
	}{
		{"path", "stackName", "region", "path,stackName,region"},
	}

	for _, tc := range testCases {

		// Setup
		testBuffer := bytes.NewBuffer(nil)

		// Run tests
		t.Run(fmt.Sprintf("%s, %s, %s", tc.path, tc.stackName, tc.region), func(t *testing.T) {
			var actual string

			err := GetUpdatedTemplate(
				tc.path,
				tc.stackName,
				tc.region,
				testBuffer,
				testUpdateStrategy,
			)
			assert.NoError(t, err, "The function does not throw an error.")

			result, _ := ioutil.ReadAll(testBuffer)

			actual = string(result)

			assert.Equal(t, tc.expected, actual, "The inputs are passed in correctly.")
		})

		// Teardown
		testBuffer = nil
	}
}
