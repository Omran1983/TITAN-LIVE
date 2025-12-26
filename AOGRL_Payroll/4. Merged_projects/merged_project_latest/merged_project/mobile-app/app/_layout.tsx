import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Stack } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import React, { useEffect } from "react";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { PayrollProvider } from "@/hooks/payroll-store";

SplashScreen.preventAutoHideAsync();

const queryClient = new QueryClient();

function RootLayoutNav() {
  return (
    <Stack screenOptions={{ headerBackTitle: "Back" }}>
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      <Stack.Screen 
        name="employee-form" 
        options={{ 
          title: "Employee Details",
          presentation: "modal",
          headerStyle: {
            backgroundColor: '#2563eb',
          },
          headerTintColor: '#fff',
        }} 
      />
      <Stack.Screen 
        name="payroll-details" 
        options={{ 
          title: "Payroll Details",
          presentation: "modal",
          headerStyle: {
            backgroundColor: '#2563eb',
          },
          headerTintColor: '#fff',
        }} 
      />
    </Stack>
  );
}

export default function RootLayout() {
  useEffect(() => {
    SplashScreen.hideAsync();
  }, []);

  return (
    <QueryClientProvider client={queryClient}>
      <PayrollProvider>
        <GestureHandlerRootView>
          <RootLayoutNav />
        </GestureHandlerRootView>
      </PayrollProvider>
    </QueryClientProvider>
  );
}