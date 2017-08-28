package command

import (
	"bytes"
	"fmt"
	"github.com/stretchr/testify/assert"
	"io/ioutil"
	"strings"
	"testing"
)

type testUpdateStrategy struct{}

func (self *testUpdateStrategy) Execute(

	path string,
	stackName string,
	region string,

) (interface{}, error) {

	return strings.Join([]string{path, stackName, region}, ","), nil
}

// TestUpdateTemplate contains unit tests for the UpdateTemplate function.
func TestGetUpdatedTemplate(t *testing.T) {

	/*
	 * Test Cases
	 */
	testCasesParams := []struct {
		path      string
		stackName string
		region    string
		expected  string
	}{
		{"path", "stackName", "region", "path,stackName,region"},
	}

	/*
	 * Test Logic
	 */
	for _, tc := range testCasesParams {

		// Setup
		testBuffer := bytes.NewBuffer(nil) // Takes the place of os.StdOut so we can see the result.

		// Run tests
		t.Run(
			fmt.Sprintf("%s, %s, %s", tc.path, tc.stackName, tc.region),
			func(t *testing.T) {
				var actual string

				err := GetUpdatedTemplate(
					tc.path,
					tc.stackName,
					tc.region,
					testBuffer,
					new(testUpdateStrategy),
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
