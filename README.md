# ci-badges

![license](https://img.shields.io/badge/license-MIT-blue.svg)

Some reusable shell scripts for creating and publishing badges based on artifacts from your builds. It helps avoid duplicating the code for report-parsing, badge-generating, and uploading across repositories.

The conventions and badge generator of [shields.io](http://shields.io/) are used.


## Usage

Create your own task script which generates and publishes badges from your job...

    $ cat > ci/tasks/publish-badges.sh
    #!/bin/sh -eu
    
    init-refs @repo/.git/HEAD $repo_branch
    
    log=artifacts/logs/coverage/clover.xml \
      ( clover-coverage && clover-lines )
      
    log=artifacts/logs/junit/results.xml \
      junit-results
      
    publish-s3

And add your task plan, including the inputs and publish parameters you'll need...

    $ cat > ci/tasks/publish-badges.yml
    ---
    platform: "linux"
    image: "docker:///dpb587/ci-badges#master"
    inputs:
      - name: "repo"
      - name: "artifacts"
    run:
      path: "repo/ci/tasks/publish-badges.sh"
    params:
      repo_branch: ~
      publish_region: ~
      publish_bucket: ~
      publish_prefix: ~
      publish_access_key: ~
      publish_secret_key: ~

Then include it in your pipeline...

    task: publish-badges
    file: repo/ci/tasks/publish-badges.yml
    params:
      repo_branch: {{repo_branch}}
      publish_bucket: my-bucket-name-us-east-1
      publish_prefix: owner-name/repo-name/
      publish_access_key: {{badge_publish_access_key}}
      publish_secret_key: {{badge_publish_secret_key}}

And badges can be referenced from the bucket...

    [![build](https://s3.amazonaws.com/my-bucket-name-us-east-1/owner-name/repo-name/master/build.svg)](https://ci.example.com/pipelines/owner-name:repo-name:master/)
    ![coverage](https://s3.amazonaws.com/my-bucket-name-us-east-1/owner-name/repo-name/master/coverage.svg)
    ![loc](https://s3.amazonaws.com/my-bucket-name-us-east-1/owner-name/repo-name/master/loc.svg)


## Generators

Generators will create a badge entry according to the variables you specify.

 * `badges_dir` - path to generate badges in (default: `/tmp/badges`)


### `badge`

Generate a custom badge.

 * **`name`** - a badge name
 * **`status`** - the status of the badge (shown on the right with colored background)
 * **`subject`** - the subject/label of the badge (shown on the left)
 * `color` - the color of the status (default: `lightgrey`)


### `clover-coverage`

Generate a green/yellow/red percentage based on a Clover Code Coverage report.

 * **`log`** - path to a Clover Coverage XML file
 * `badge_name` - badge name to use (default: `coverage`)
 * `badge_subject` - badge subject to use (default: `$badge_name`)
 * `percent_green` - threshold percentage for green (default: `80`)
 * `percent_yellow` - threshold percentage for yellow (default: `50`)


### `clover-lines`

Generate an informational badge showing the number of lines of code.

 * **`log`** - path to a Clover Coverage XML file
 * `badge_color` - badge color to use (default: `yellowgreen`)
 * `badge_name` - badge name to use (default: `loc`)
 * `badge_subject` - badge subject to use (default: `$badge_name`)


### `junit-results`

Generate a passing/failing badge based on a JUnit report.

 * **`log`** - path to a JUnit XML file
 * `badge_name` - badge name to use (default: `build`)
 * `badge_subject` - badge subject to use (default: `$badge_name`)


## Publishers

Publishers will publish a badge entry by uploading the [shields.io](http://shields.io/)-generated badge to your destination. Publisher-specific variable names should be `publish_`-prefixed.

 * `badges_dir` - path to publish badges from (default: `/tmp/badges`)


### `publish-s3`

Uploads badges to a bucket with a key in the format of `{prefix}?{ref}/{badge_name}.svg`.

 * **`publish_bucket`** - bucket name
 * `publish_access_key` - access key
 * `publish_prefix` - prefix for ref and badge files
 * `publish_region` - region the bucket is located (default: `us-east-1`)
 * `publish_secret_key` - secret key

You might want to create a restricted IAM User for uploading to bucket...

    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
              "s3:PutObject"
          ],
          "Resource": [
              "arn:aws:s3:::my-bucket-name-us-east-1/*"
          ]
        }
      ]
    }

And you might want to make the bucket publicly readable so badges can show up in GitHub and other frontends...

    {
    	"Version": "2012-10-17",
    	"Statement": [
    		{
    			"Effect": "Allow",
    			"Principal": "*",
    			"Action": "s3:GetObject",
    			"Resource": "arn:aws:s3:::my-bucket-name-us-east-1/*"
    		}
    	]
    }


## License

[MIT License](./LICENSE)
