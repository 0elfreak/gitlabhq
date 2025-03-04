---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tracing (DEPRECATED) **(FREE SELF)**

> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/42645) from GitLab Ultimate to GitLab Free in 13.5.
> - [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/346540) in GitLab 14.7.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/359904) behind a [feature flag](../administration/feature_flags.md) named `monitor_tracing` in GitLab 15.0. Disabled by default.

WARNING:
This feature is in its end-of-life process. It is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/346540)
in GitLab 14.7.
It will be removed completely in GitLab 15.2.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../administration/feature_flags.md) named `monitor_tracing`.
On GitLab.com, this feature is not available.
This feature is not recommended for production use.

Tracing provides insight into the performance and health of a deployed application, tracking each
function or microservice that handles a given request. Tracing makes it easy to understand the
end-to-end flow of a request, regardless of whether you are using a monolithic or distributed
system.

## Install Jaeger

[Jaeger](https://www.jaegertracing.io/) is an open source, end-to-end distributed tracing system
used for monitoring and troubleshooting microservices-based distributed systems. To learn more about
installing Jaeger, read the official
[Getting Started documentation](https://www.jaegertracing.io/docs/latest/getting-started/).

See also:

- An [all-in-one Docker image](https://www.jaegertracing.io/docs/latest/getting-started/#all-in-one).
- Deployment options for:
  - [Kubernetes](https://github.com/jaegertracing/jaeger-kubernetes).
  - [OpenShift](https://github.com/jaegertracing/jaeger-openshift).

## Link to Jaeger

GitLab provides an easy way to open the Jaeger UI from within your project:

1. [Set up Jaeger](https://www.jaegertracing.io) and configure your application using one of the
   [client libraries](https://www.jaegertracing.io/docs/latest/client-libraries/).
1. Navigate to your project's **Settings > Monitor** and provide the Jaeger URL.
1. Select **Save changes** for the changes to take effect.
1. You can now visit **Monitor > Tracing** in your project's sidebar and GitLab redirects you to
   the configured Jaeger URL.
