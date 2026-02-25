package br.com.geac.backend.Aplication.Services;

import br.com.geac.backend.Domain.Entities.Event;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Log4j2
@Service
@RequiredArgsConstructor
public class EmailService {

    @Value("${spring.mail.username}")
    private String remetente;
    private final JavaMailSender mailSender;

    public void sendAlert(String email,Event event){
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(remetente);
        message.setTo(email);
        message.setSubject("ALERT" + event.getTitle());
        message.setText(buildMessage(event));
        //TODO: descomentar dps mailSender.send(message);
        log.info("SENDING ALERT" + message.getText());
    }

    private String buildMessage(Event event){
        return String.format(
                "Olá cidadao" + "o evento que tu ta inscrito '%s' + %s/n jaja acontece, Data: %s/n, Local: %s/n",
                event.getTitle(), event.getDescription(),event.getStartTime(), event.getLocation()
        );
    }
}
