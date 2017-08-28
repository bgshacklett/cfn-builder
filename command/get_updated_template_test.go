package command

import (
	"bytes"
	"extropy/cfn"
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

	testBuffer := bytes.NewBuffer(nil)

	expected := "path,stackName,region"
	var actual string

	err := GetUpdatedTemplate(
		"path",
		"stackName",
		"region",
		testBuffer,
		testUpdateStrategy,
	)
	assert.NoError(t, err, "The function does not throw an error.")

	result, _ := ioutil.ReadAll(testBuffer)

	actual = string(result)

	assert.Equal(t, expected, actual, "The inputs are passed in correctly.")
}
