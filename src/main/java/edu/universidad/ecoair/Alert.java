package edu.universidad.ecoair;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class Alert {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String sensor;
    private String message;

    protected Alert() { }

    public Alert(String sensor, String message) {
        this.sensor = sensor;
        this.message = message;
    }

    public Long getId() { return id; }
    public String getSensor() { return sensor; }
    public String getMessage() { return message; }
}
