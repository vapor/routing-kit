# Contributing to Vapor

👋 Welcome to the Vapor team! We're happy to have you. Check out our 
[Code of Conduct](https://github.com/vapor/vapor/blob/master/Docs/code_of_conduct.md) if you haven't already, and 
join us on [discord](https://vapor.team) if you run into trouble.

## Getting Started

To get started, you will need to open a Terminal and:

1. Fork this repo and clone it onto your machine.
```
$ git clone https://github.com/<YourGitHubName>/routing-kit
```
2. Make some changes. A good place to start if you're looking for ideas are the open 
[issues](https://github.com/vapor/routing-kit/issues). If nothing looks good to you, but you still want
to help, ask around in the [Discord](https://vapor.team)

2.5. Some macOS folks find it easier to do development with Xcode. Xcode projects aren't checked into
github, but if you'd like to generate one, run `vapor xcode` in the project directory and answer the
prompts.

3. Ensure your tests pass by either running `vapor test` on the command line, or pressing `CMD+U` 
within Xcode.

4. If everything passes, congrats! You've made a successful change 🎉Now you get to open a pull request
(PR) on Github.


## Pull Requests

To open a pull request, go to your fork on Github and select the "New pull request" button. You'll be
directed to a new page where you can compare your changes with the current state of the project. Make
sure you have `vapor/routing-kit` and `base: master` selected on the left and `<YourGithubUsername>/routing`
and `compare: master` selected on the right. Below that you'll see the changes you've made. Make sure
you're seeing the changes you expect.

If everything looks right, select the big green "Create pull request" button.

You'll be presented with a pull request template with some sections for you to fill in. Once you've 
filled out each section and written a title that describes your changes, open your pull request and a
maintainer should be by soon to review it.

## Reporting Issues
	
Go ahead and [open a new issue](https://github.com/vapor/routing-kit/issues/new). The team will be notified
and we should get back to you shortly.
	
We give you a few sections to fill out to help us hunt down the issue more effectively. Be sure to fill
everything out to help us get everything fixed up as fast as possible.

## Maintainers

- [@twof](https://github.com/twof)

See the [Vapor maintainers doc](https://github.com/vapor/vapor/blob/master/Docs/maintainers.md) for more information.

## SemVer

Vapor follows [SemVer](https://semver.org). This means that any changes to the source code that can cause
existing code to stop compiling _must_ wait until the next major version to be included. 

Code that is only additive and will not break any existing code can be included in the next minor release.

## Testing

Once in Xcode, select the `routing-kit-Package` scheme and use `CMD+U` to run the tests.

&mdash; Thanks! 🙌
