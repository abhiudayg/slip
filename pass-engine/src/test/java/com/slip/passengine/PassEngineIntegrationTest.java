package com.slip.passengine;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class PassEngineIntegrationTest {
  @Autowired MockMvc mockMvc;

  @DynamicPropertySource
  static void props(DynamicPropertyRegistry registry) {
    Path root = Path.of("..").toAbsolutePath().normalize();
    registry.add("slip.templates-dir", () -> root.resolve("templates").toString());
    registry.add("slip.stations-dir", () -> root.resolve("stations").toString());
    registry.add("slip.dev-mode", () -> "true");
  }

  @Test
  void listsBrands() throws Exception {
    mockMvc.perform(get("/v1/brands"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[?(@.id=='upi')]").exists())
        .andExpect(jsonPath("$[?(@.id=='cult')]").exists())
        .andExpect(jsonPath("$[?(@.id=='namma-metro')]").exists())
        .andExpect(jsonPath("$[?(@.id=='bookmyshow')]").exists());
  }

  @Test
  void loadsNammaMetroStations() throws Exception {
    mockMvc.perform(get("/v1/stations/namma-metro"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.stations[0].id").exists())
        .andExpect(jsonPath("$.stations[?(@.id=='IND')].name").value("Indiranagar"));
  }

  @Test
  void createsUpiPass() throws Exception {
    String body = """
        {
          "template": "upi",
          "fields": {
            "name": "Abhiuday",
            "qr_data": "upi://pay?pa=user@upi&pn=Abhiuday"
          }
        }
        """;
    mockMvc.perform(post("/v1/passes").contentType(MediaType.APPLICATION_JSON).content(body))
        .andExpect(status().isOk())
        .andExpect(header().string("Content-Type", "application/vnd.apple.pkpass"));
  }

  @Test
  void createsMetroPassWithStations() throws Exception {
    String body = """
        {
          "template": "namma-metro",
          "fields": {
            "origin": "Indiranagar",
            "destination": "Majestic / Nadaprabhu Kempegowda",
            "qr_data": "METRO-TICKET-DEMO",
            "passenger": "Abhiuday"
          },
          "stationIds": ["IND", "MJL"]
        }
        """;
    mockMvc.perform(post("/v1/passes").contentType(MediaType.APPLICATION_JSON).content(body))
        .andExpect(status().isOk());
  }
}
