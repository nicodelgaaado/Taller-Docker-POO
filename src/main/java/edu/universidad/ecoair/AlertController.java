package edu.universidad.ecoair;

import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/alerts")
public class AlertController {
    private final AlertRepository alerts;

    public AlertController(AlertRepository alerts) {
        this.alerts = alerts;
    }

    @GetMapping
    public List<Alert> list() {
        return alerts.findAll();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Alert create(@RequestBody AlertInput input) {
        return alerts.save(new Alert(input.sensor(), input.message()));
    }

    public record AlertInput(String sensor, String message) { }
}
