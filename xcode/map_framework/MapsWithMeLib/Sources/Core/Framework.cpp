#include "Framework.h"

#include "base/assert.hpp"

static Framework * g_framework = 0;
bool g_wasDeleted = false;

Framework & GetFramework()
{
  CHECK(!g_wasDeleted, ());
  if (g_framework == 0)
      g_framework = new Framework(FrameworkParams(false, true));
  return *g_framework;
}

void DeleteFramework()
{
  g_wasDeleted = true;
  delete g_framework;
  g_framework = nullptr;
}
