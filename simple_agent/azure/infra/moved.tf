# Preserve the deployed agent's state address after extracting it into the child module.
moved {
  from = azapi_data_plane_resource.hosted_agent
  to   = module.hosted_agent.azapi_data_plane_resource.hosted_agent
}
