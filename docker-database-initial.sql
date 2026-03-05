CREATE
EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE categories
(
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE locations
(
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    street          VARCHAR(150) NOT NULL,
    number          VARCHAR(20),
    neighborhood    VARCHAR(100) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    state           VARCHAR(2)   NOT NULL,
    zip_code        VARCHAR(10)  NOT NULL,
    campus          VARCHAR(100) NOT NULL,
    reference_point TEXT,
    capacity        INTEGER      NOT NULL
);

CREATE TABLE users
(
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name     VARCHAR(150) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    user_type     VARCHAR(20),
    created_at    TIMESTAMP        DEFAULT NOW()
);

CREATE TABLE requirements
(
    id          SERIAL PRIMARY KEY,
    description VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE tags
(
    id   SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE speakers
(
    id    SERIAL PRIMARY KEY,
    name  VARCHAR(150) NOT NULL,
    bio   TEXT,
    email VARCHAR(100)
);

CREATE TABLE speaker_qualifications
(
    id          SERIAL PRIMARY KEY,
    speaker_id  INTEGER      NOT NULL REFERENCES speakers (id) ON DELETE CASCADE,
    title_name  VARCHAR(100) NOT NULL, -- Ex: "Doutor em Ciência da Computação"
    institution VARCHAR(100) NOT NULL  -- Ex: "USP"
);

CREATE TABLE organizers
(
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name          VARCHAR(100) NOT NULL UNIQUE,
    contact_email VARCHAR(100) NOT NULL
);

CREATE TABLE organizer_members
(
    id           SERIAL PRIMARY KEY,
    organizer_id UUID NOT NULL REFERENCES organizers (id) ON DELETE CASCADE,
    user_id      UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (organizer_id, user_id)
);

CREATE TABLE events
(
    id                 UUID PRIMARY KEY      DEFAULT uuid_generate_v4(),
    organizer_id       UUID         NOT NULL REFERENCES organizers (id),
    category_id        INTEGER      NOT NULL REFERENCES categories (id),
    location_id        INTEGER REFERENCES locations (id),

    title              VARCHAR(200) NOT NULL,
    description        TEXT         NOT NULL,
    online_link        VARCHAR(255),

    start_time         TIMESTAMP    NOT NULL,
    end_time           TIMESTAMP    NOT NULL,
    workload_hours     INTEGER      NOT NULL,
    max_capacity       INTEGER      NOT NULL,
    days_before_notify VARCHAR(25)  NOT NULL DEFAULT 'ONE_DAY_BEFORE' CHECK ( days_before_notify IN ('ONE_DAY_BEFORE', 'ONE_WEEK_BEFORE')),
--     requirement_id INTEGER              NOT NULL REFERENCES requirements (id), -- ✅ REMOVIDO: O relacionamento de requisitos agora é muitos-para-muitos, então essa coluna foi removida --- IGNORE ---
    status             VARCHAR(20), -- DEFAULT 'UPCOMING' CHECK ( status IN ('UPCOMING', 'ACTIVE', 'IN_PROGRESS', 'COMPLETED','CANCELLED') ),
    created_at         TIMESTAMP             DEFAULT NOW()
);

CREATE TABLE event_speakers
(
    event_id   UUID    NOT NULL REFERENCES events (id) ON DELETE CASCADE,
    speaker_id INTEGER NOT NULL REFERENCES speakers (id) ON DELETE CASCADE,
    PRIMARY KEY (event_id, speaker_id)
);

CREATE TABLE event_requirements
(
    event_id       UUID    NOT NULL REFERENCES events (id) ON DELETE CASCADE,
    requirement_id INTEGER NOT NULL REFERENCES requirements (id) ON DELETE CASCADE,
    PRIMARY KEY (event_id, requirement_id)
);


-- SÓ AGORA CRIAMOS EVENT_TAGS
CREATE TABLE event_tags
(
    event_id UUID    NOT NULL REFERENCES events (id),
    tag_id   INTEGER NOT NULL REFERENCES tags (id),
    PRIMARY KEY (event_id, tag_id)
);

CREATE TABLE organizer_requests
(
    id            SERIAL PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    organizer_id  UUID NOT NULL REFERENCES organizers (id) ON DELETE CASCADE,
    justification TEXT,
    status        VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    created_at    TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    resolved_at   TIMESTAMP
);

CREATE TABLE notifications
(
    id         SERIAL PRIMARY KEY,
    user_id    UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    event_id   UUID REFERENCES events (id) ON DELETE CASCADE,
    status     BOOLEAN     DEFAULT FALSE,
    type       VARCHAR(25) DEFAULT 'REMINDER' CHECK (type IN ('REMINDER', 'SUBSCRIBE', 'CANCEL', 'APPROVED', 'REQUEST',
                                                              'REJECTED')),
    title      VARCHAR(255),
    message    TEXT,
    created_at TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE certificates
(
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    event_id        UUID         NOT NULL REFERENCES events (id) ON DELETE CASCADE,
    validation_code VARCHAR(100) NOT NULL UNIQUE,
    issued_at       TIMESTAMP        DEFAULT NOW()
);

CREATE TABLE registrations
(
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attended          BOOLEAN          DEFAULT FALSE,
    notified          BOOLEAN          DEFAULT FALSE,
    registration_date TIMESTAMP        DEFAULT NOW(),
    user_id           UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    event_id          UUID NOT NULL REFERENCES events (id) ON DELETE CASCADE,
    UNIQUE (user_id, event_id)
);

CREATE TABLE evaluations
(
    id              SERIAL PRIMARY KEY,
    comment         TEXT,
    created_at      TIMESTAMP DEFAULT NOW(),
    rating          INTEGER CHECK (rating >= 1 AND rating <= 5),
    registration_id UUID NOT NULL REFERENCES registrations (id) ON DELETE CASCADE,
    UNIQUE (registration_id)
);

CREATE
OR REPLACE VIEW vw_horas_extracurriculares_aluno AS
SELECT u.id                               AS student_id,
       u.full_name                        AS student_name,
       u.email                            AS student_email,
       COUNT(c.id)                        AS total_certificados_emitidos,
       COALESCE(SUM(e.workload_hours), 0) AS total_horas_acumuladas
FROM users u
         LEFT JOIN certificates c ON u.id = c.user_id
         LEFT JOIN events e ON c.event_id = e.id
WHERE u.user_type = 'STUDENT'
GROUP BY u.id, u.full_name, u.email;

CREATE
OR REPLACE VIEW vw_eventos_estatisticas AS
SELECT e.id                                               AS event_id,
       e.title                                            AS event_title,
       e.status                                           AS event_status,
       COUNT(DISTINCT r.id)                               AS total_inscritos,
       SUM(CASE WHEN r.attended = TRUE THEN 1 ELSE 0 END) AS total_presentes,
       ROUND(AVG(ev.rating), 2)                           AS media_avaliacao
FROM events e
         LEFT JOIN registrations r ON e.id = r.event_id
         LEFT JOIN evaluations ev ON r.id = ev.registration_id
GROUP BY e.id, e.title, e.status;

CREATE
OR REPLACE VIEW vw_engajamento_organizacoes AS
SELECT o.id                                                            AS organizer_id,
       o.name                                                          AS organizer_name,
       COUNT(DISTINCT e.id)                                            AS total_eventos_realizados,
       COALESCE(SUM(CASE WHEN r.attended = TRUE THEN 1 ELSE 0 END), 0) AS total_participantes_engajados
FROM organizers o
         LEFT JOIN events e ON o.id = e.organizer_id
         LEFT JOIN registrations r ON e.id = r.event_id
GROUP BY o.id, o.name;


-- POVOAMENTO

INSERT INTO public.users (id, full_name, email, password_hash, user_type, created_at)
VALUES ('f7d2e9b8-31a4-4c5d-92e1-8b0f7a63c294', 'Administrador 2', 'admin@geac.com',
        '$2y$10$/5w0baJ/4H4MrN98n9Ika.T8mW8fOSJTr1MhKFp2E.QyPoh985ND2', 'ADMIN', NOW()),
       ('be89dede-00f2-48eb-880b-c9b728ce5bfc', 'student1', 'student1@test.com',
        '$2a$10$kXz14cSQ4CuM8ev7MKWtQu1/4Ny7v/ic5xuQxgwZzh.x9ZHLuxOM2', 'STUDENT', NOW()),
       ('b82120cf-41a7-406a-b52d-259cdbef3041', 'student2', 'student2@test.com',
        '$2a$10$.bW0KlZDt.tkGrj6xxTgL./OoUtYrmaq3re.ABGjN7u4pHnnl.k3G', 'STUDENT', NOW()),
       ('5c0a92a1-b445-4e4b-807c-6fbca67b9092', 'student3', 'student3@test.com',
        '$2a$10$TTE/WAR4tTdILrWFdC7aDOT1lJzwHpNVY8MYBiHkw1q6Ki3oQFy7G', 'STUDENT', NOW()),
       ('9be3d05c-7638-4f78-814a-ce4c21463262', 'student4', 'student4@test.com',
        '$2a$10$6R/amLD0hO1oMDMyCSiA4.jCJgcKuPgYFv9wxpmLt9d0Fx/YXyR9q', 'STUDENT', NOW()),
       ('286c2d18-9814-4d88-a55d-14bacaefcf49', 'student5', 'student5@test.com',
        '$2a$10$kWOVCbnEdBKwoirx8IvxxuBC1r5TS8O8/ekLd1JkAKlVvW6rDLajy', 'STUDENT', NOW()),
       ('073b9076-2317-4511-a9c3-535654e75363', 'professor1', 'professor1@test.com',
        '$2a$10$UAH/nCUUYJ6Cklr79GLUVuY91SBHZh.JmyP/Id6NdnTBvhG6m5Vma', 'PROFESSOR', NOW()),
       ('be4999bf-6d31-4414-a0a6-ae61d53a6387', 'professor2', 'professor2@test.com',
        '$2a$10$MOljMoo4PYuoz4yzBJK8K.tW/2iBtWFcFUkZv8d5RuGfIMikJITDu', 'PROFESSOR', NOW()),
       ('54307ac7-8117-42c3-abc2-a74b112979c3', 'professor3', 'professor3@test.com',
        '$2a$10$q0K2zMKAZ2w0XRTektFvcO1TiQ1IKFTSp.biRbH6W9.uL5IcFDrgG', 'PROFESSOR', NOW()),
       ('e6137fdc-6fc2-4776-8616-9e238c1b48a7', 'admin', 'admin@admin.com',
        '$2a$10$/h/iWZLAhU4PfZmTew1nl.6xfNP4ymHEu5zSWXGhGIsce41x7p146', 'ADMIN', NOW()),
       ('11111111-1111-1111-1111-111111111111', 'Ana Silva Santos', 'ana.silva@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('22222222-2222-2222-2222-222222222222', 'Bruno Oliveira Costa', 'bruno.oliveira@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('33333333-3333-3333-3333-333333333333', 'Carla Souza Lima', 'carla.souza@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('44444444-4444-4444-4444-444444444444', 'Daniel Pereira Alves', 'daniel.pereira@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('55555555-5555-5555-5555-555555555555', 'Eduarda Ferreira Rocha', 'eduarda.ferreira@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('66666666-6666-6666-6666-666666666666', 'Felipe Rodrigues Martins', 'felipe.rodrigues@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('77777777-7777-7777-7777-777777777777', 'Gabriela Santos Ribeiro', 'gabriela.santos@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('88888888-8888-8888-8888-888888888888', 'Henrique Almeida Gomes', 'henrique.almeida@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('99999999-9999-9999-9999-999999999999', 'Isabela Costa Araújo', 'isabela.costa@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'João Pedro Lima Silva', 'joao.pedro@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Juliana Martins Cardoso', 'juliana.martins@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Kaique Barbosa Teixeira', 'kaique.barbosa@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Larissa Mendes Correia', 'larissa.mendes@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Matheus Cavalcanti Nunes', 'matheus.cavalcanti@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'Natália Cunha Dias', 'natalia.cunha@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('10101010-1010-1010-1010-101010101010', 'Otávio Moreira Castro', 'otavio.moreira@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('20202020-2020-2020-2020-202020202020', 'Paula Ramos Freitas', 'paula.ramos@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('30303030-3030-3030-3030-303030303030', 'Rafael Soares Batista', 'rafael.soares@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('40404040-4040-4040-4040-404040404040', 'Sabrina Carvalho Moura', 'sabrina.carvalho@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('50505050-5050-5050-5050-505050505050', 'Thiago Nascimento Lopes', 'thiago.nascimento@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('60606060-6060-6060-6060-606060606060', 'Vitória Azevedo Farias', 'vitoria.azevedo@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('70707070-7070-7070-7070-707070707070', 'William Barros Medeiros', 'william.barros@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('80808080-8080-8080-8080-808080808080', 'Yasmin Fernandes Pinto', 'yasmin.fernandes@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('90909090-9090-9090-9090-909090909090', 'Arthur Duarte Monteiro', 'arthur.duarte@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', 'Bianca Viana Campos', 'bianca.viana@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2', 'Caio Machado Rezende', 'caio.machado@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3', 'Débora Pires Santana', 'debora.pires@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('d4d4d4d4-d4d4-d4d4-d4d4-d4d4d4d4d4d4', 'Eduardo Teixeira Xavier', 'eduardo.teixeira@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('e5e5e5e5-e5e5-e5e5-e5e5-e5e5e5e5e5e5', 'Fernanda Miranda Guedes', 'fernanda.miranda@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),
       ('f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6', 'Gustavo Fonseca Borges', 'gustavo.fonseca@email.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'STUDENT', NOW()),

-- Professores (15)
       ('a0a0a0a0-a0a0-a0a0-a0a0-a0a0a0a0a0a0', 'Prof. Alice Tavares Melo', 'alice.tavares@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('b0b0b0b0-b0b0-b0b0-b0b0-b0b0b0b0b0b0', 'Prof. Bernardo Vieira Campos', 'bernardo.vieira@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('c0c0c0c0-c0c0-c0c0-c0c0-c0c0c0c0c0c0', 'Prof. Cecília Andrade Prado', 'cecilia.andrade@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('d0d0d0d0-d0d0-d0d0-d0d0-d0d0d0d0d0d0', 'Prof. Diego Campos Braga', 'diego.campos@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('e0e0e0e0-e0e0-e0e0-e0e0-e0e0e0e0e0e0', 'Prof. Eliana Moura Figueiredo', 'eliana.moura@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('f0f0f0f0-f0f0-f0f0-f0f0-f0f0f0f0f0f0', 'Prof. Fábio Neves Pacheco', 'fabio.neves@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('a1b1c1d1-a1b1-c1d1-a1b1-c1d1a1b1c1d1', 'Prof. Giovana Ribeiro Torres', 'giovana.ribeiro@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('a2b2c2d2-a2b2-c2d2-a2b2-c2d2a2b2c2d2', 'Prof. Hugo Silveira Barreto', 'hugo.silveira@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('a3b3c3d3-a3b3-c3d3-a3b3-c3d3a3b3c3d3', 'Prof. Ísis Freire Aragão', 'isis.freire@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('a4b4c4d4-a4b4-c4d4-a4b4-c4d4a4b4c4d4', 'Prof. Júlio César Leal', 'julio.cesar@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('a5b5c5d5-a5b5-c5d5-a5b5-c5d5a5b5c5d5', 'Prof. Kátia Farias Ventura', 'katia.farias@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('a6b6c6d6-a6b6-c6d6-a6b6-c6d6a6b6c6d6', 'Prof. Leonardo Amaral Souto', 'leonardo.amaral@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('a7b7c7d7-a7b7-c7d7-a7b7-c7d7a7b7c7d7', 'Prof. Márcia Dias Vargas', 'marcia.dias@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('a8b8c8d8-a8b8-c8d8-a8b8-c8d8a8b8c8d8', 'Prof. Nilton Peixoto Castro', 'nilton.peixoto@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),
       ('a9b9c9d9-a9b9-c9d9-a9b9-c9d9a9b9c9d9', 'Prof. Olga Correia Valente', 'olga.correia@professor.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'PROFESSOR', NOW()),

-- Administradores (5)
       ('ad111111-1111-1111-1111-111111111111', 'Roberto Macedo Filho', 'roberto.macedo@admin.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'ADMIN', NOW()),
       ('ad222222-2222-2222-2222-222222222222', 'Simone Costa Bezerra', 'simone.costa@admin.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'ADMIN', NOW()),
       ('ad333333-3333-3333-3333-333333333333', 'Tânia Rocha Montenegro', 'tania.rocha@admin.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'ADMIN', NOW()),
       ('ad444444-4444-4444-4444-444444444444', 'Ubirajara Santos Lima', 'ubirajara.santos@admin.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'ADMIN', NOW()),
       ('ad555555-5555-5555-5555-555555555555', 'Vanessa Albuquerque Silva', 'vanessa.albuquerque@admin.com',
        '$2y$10$3.44QK3jKHZt1bEMr2Xhn.PprpL2D/BZC5.9tipQcednY2Cm2ZTPy', 'ADMIN', NOW());


-- 50 CATEGORIAS
INSERT INTO categories (name, description)
VALUES ('hackathon', 'Competições intensivas de programação e inovação para solução de desafios.'),
       ('palestra', 'Apresentações curtas e focadas sobre temas específicos com especialistas.'),
       ('seminario', 'Encontros acadêmicos ou profissionais para discussão aprofundada de estudos.'),
       ('cultural', 'Eventos artísticos, exposições, teatro, música e expressões populares.'),
       ('feira', 'Exposições comerciais, networking e demonstração de produtos ou serviços.'),
       ('workshop', 'Atividades práticas e treinamentos para desenvolvimento de habilidades.'),
       ('livre', 'Eventos de formato aberto, lazer ou sem uma estrutura rígida pré-definida.'),
       ('conferencia', 'Grandes reuniões formais com múltiplos palestrantes e debates temáticos.'),
       ('festival', 'Celebrações amplas com diversas atividades simultâneas e entretenimento.'),
       ('outro', 'Categorias que não se enquadram nas definições anteriores.'),
       ('Programação Web', 'Desenvolvimento de sites e sistemas web.'),
       ('Saúde Coletiva', 'Estudos e práticas sobre saúde pública.'),
       ('Empreendedorismo', 'Inovação e novos modelos de negócio.'),
       ('Inteligência Artificial', 'Machine learning e redes neurais.'),
       ('Direito Civil', 'Debates sobre legislação e normas civis.'),
       ('Gestão de Projetos', 'Metodologias ágeis e tradicionais.'),
       ('Design de Experiência', 'Foco no usuário e interfaces.'),
       ('Engenharia de Software', 'Processos e qualidade de código.'),
       ('Marketing Digital', 'Estratégias para redes sociais e SEO.'),
       ('Finanças Pessoais', 'Educação financeira para estudantes.'),
       ('Cibersegurança', 'Proteção de dados e redes.'),
       ('Data Science', 'Análise de grandes volumes de dados.'),
       ('Arquitetura de Nuvem', 'AWS, Azure e Google Cloud.'),
       ('Desenvolvimento Mobile', 'Apps para Android e iOS.'),
       ('Soft Skills', 'Comunicação e liderança.'),
-- ... (repetir padrões para atingir 50)
       ('Robótica', 'Construção e programação de robôs.'),
       ('Educação Inclusiva', 'Métodos de ensino adaptados.'),
       ('Energias Renováveis', 'Sustentabilidade e energia solar.'),
       ('Psicologia Organizacional', 'Comportamento humano no trabalho.'),
       ('Bioinformática', 'Tecnologia aplicada à biologia.'),
       ('Blockchain', 'Criptoativos e contratos inteligentes.'),
       ('Internet das Coisas', 'Dispositivos conectados.'),
       ('Realidade Virtual', 'Imersão e simulações digitais.'),
       ('Ética na Tecnologia', 'Privacidade e viés algorítmico.'),
       ('Metodologias Ativas', 'Novas formas de aprender.'),
       ('Sustentabilidade Urbana', 'Cidades inteligentes e verdes.'),
       ('Logística e Supply Chain', 'Cadeia de suprimentos eficiente.'),
       ('Gastronomia Regional', 'Culinária do Nordeste brasileiro.'),
       ('História de Pernambuco', 'Raízes e cultura do estado.'),
       ('Literatura Brasileira', 'Clássicos e novos autores.'),
       ('Fotografia Digital', 'Técnicas de iluminação e edição.'),
       ('Produção Audiovisual', 'Criação de vídeos e podcasts.'),
       ('Gestão Pública', 'Administração de bens e serviços.'),
       ('Direito do Trabalho', 'Relações entre patrão e empregado.'),
       ('Contabilidade Geral', 'Balanços e demonstrações financeiras.'),
       ('Nutrição Esportiva', 'Dieta aplicada ao rendimento.'),
       ('Fisioterapia Preventiva', 'Exercícios para evitar lesões.'),
       ('Enfermagem Obstétrica', 'Cuidados no parto e pós-parto.'),
       ('Odontologia Social', 'Saúde bucal para comunidades.'),
       ('Agronomia Tropical', 'Cultivo em climas quentes.'),
       ('Medicina Veterinária', 'Cuidado com pequenos animais.'),
       ('Farmácia Clínica', 'Interações medicamentosas.'),
       ('Artes Visuais', 'Pintura, escultura e design.'),
       ('Música e Tecnologia', 'Produção fonográfica digital.'),
       ('Teatro e Expressão', 'Artes cênicas e comunicação.'),
       ('Astronomia Amadora', 'Observação dos astros.'),
       ('Física Quântica', 'Conceitos básicos e avançados.'),
       ('Química Industrial', 'Processos químicos em larga escala.'),
       ('Matemática Aplicada', 'Cálculos para engenharia.'),
       ('Sociologia Rural', 'Estudos do campo e sociedade.');

-- 50 REQUISITOS (EXEMPLOS)
INSERT INTO requirements (description)
VALUES ('Trazer notebook'),
       ('$5 para corpo docente/funcionários'),
       ('Aberto a todos os alunos e corpo docente'),
       ('Aberto a todos os estudantes'),
       ('Conhecimento básico de marketing é útil'),
       ('Entrada gratuita'),
       ('Estudantes: grátis'),
       ('Inscrição necessária para vales-alimentação'),
       ('Recomendado entendimento básico de criptomoedas'),
       ('Recomendado para estudantes de Ciências Ambientais e áreas relacionadas'),
       ('Traje esporte fino recomendado'),
       ('Trajar currículos impressos'),
       ('Conhecimento prévio em Python recomendado'),
       ('Material de anotação (caderno e caneta)'),
       ('Certificado de conclusão será emitido'),
       ('Vagas limitadas - inscrição obrigatória'),
       ('Recomendado para estudantes de Engenharia'),
       ('Trazer documentos de identificação'),
       ('Conhecimento básico de inglês é desejável'),
       ('Aberto ao público externo mediante inscrição'),
       ('Taxa de R$ 10,00 para não estudantes'),
       ('Necessário ter conta no GitHub'),
       ('Recomendado para iniciantes'),
       ('Conhecimento intermediário em Java'),
       ('Trazer dispositivo móvel (smartphone ou tablet)'),
       ('Certificado digital disponível após avaliação'),
       ('Inscrição limitada a 50 participantes'),
       ('Recomendado para estudantes de Administração e Economia'),
       ('Necessário cadastro prévio no sistema'),
       ('Coffee break incluso'),
       ('Material didático será fornecido'),
       ('Trazer fones de ouvido'),
       ('Conhecimento básico de estatística recomendado'),
       ('Aberto apenas para alunos matriculados'),
       ('Necessário experiência prévia com SQL'),
       ('Recomendado para estudantes de Design e Comunicação'),
       ('Trazer portfolio digital ou impresso'),
       ('Vestimenta casual permitida'),
       ('Conhecimento em Git e controle de versão'),
       ('Necessário laptop com mínimo 8GB RAM'),
       ('Recomendado para estudantes do último período'),
       ('Taxa de inscrição: R$ 15,00 (não reembolsável)'),
       ('Certificado válido para horas complementares'),
       ('Necessário conhecimento em Docker'),
       ('Recomendado para profissionais da área de TI'),
       ('Trazer projeto pessoal para apresentação'),
       ('Conhecimento em bancos de dados NoSQL'),
       ('Inscrição gratuita com desconto para grupos'),
       ('Necessário ter perfil atualizado no LinkedIn'),
       ('Recomendado para estudantes de Ciências da Computação');

-- 50 TAGS
-- 50 TAGS
INSERT INTO tags (name)
VALUES ('apoio'),
       ('artes'),
       ('bem-estar'),
       ('blockchain'),
       ('carreira'),
       ('ciência'),
       ('clima'),
       ('criptomoedas'),
       ('cultura'),
       ('digital'),
       ('diversidade'),
       ('empregos'),
       ('estudantes'),
       ('festival'),
       ('finanças'),
       ('ia'),
       ('inovação'),
       ('internacional'),
       ('marketing'),
       ('meio ambiente'),
       ('música'),
       ('negócios'),
       ('networking'),
       ('performance'),
       ('rock'),
       ('saúde mental'),
       ('sustentabilidade'),
       ('tecnologia'),
       ('workshop'),
       ('programação'),
       ('dados'),
       ('design'),
       ('empreendedorismo'),
       ('educação'),
       ('pesquisa'),
       ('segurança'),
       ('cloud'),
       ('mobile'),
       ('web'),
       ('soft skills'),
       ('liderança'),
       ('gestão'),
       ('startups'),
       ('jogos'),
       ('esportes'),
       ('cinema'),
       ('fotografia'),
       ('literatura'),
       ('engenharia'),
       ('arquitetura'),
       ('jurídico');

-- 50 PALESTRANTES
INSERT INTO speakers (name, bio, email)
VALUES ('Dr. Alan Turing', 'Pai da computação e especialista em IA.', 'alan.turing@example.com'),
       ('Dra. Marie Curie', 'Pesquisadora em física e química.', 'marie.curie@example.com'),
       ('Grace Hopper', 'Pioneira na programação e criadora do COBOL.', 'grace.hopper@example.com'),
       ('Nikola Tesla', 'Inovador em sistemas de energia elétrica.', 'nikola.tesla@example.com'),
       ('Ada Lovelace', 'Primeira programadora da história.', 'ada.lovelace@example.com'),
       ('Richard Feynman', 'Físico teórico e Nobel de Física.', 'richard.feynman@example.com'),
       ('Margaret Hamilton', 'Diretora de engenharia de software da missão Apollo.', 'margaret.hamilton@example.com'),
       ('Carl Sagan', 'Astrofísico e divulgador científico.', 'carl.sagan@example.com'),
       ('Hedy Lamarr', 'Inventora da base para o Wi-Fi e Bluetooth.', 'hedy.lamarr@example.com'),
       ('Steve Wozniak', 'Cofundador da Apple e engenheiro de hardware.', 'steve.wozniak@example.com'),
       ('Dr. Tim Berners-Lee', 'Inventor da World Wide Web.', 'tim.berners@example.com'),
       ('Linus Torvalds', 'Criador do Linux e do Git.', 'linus.torvalds@example.com'),
       ('Dra. Jane Goodall', 'Primatologista e defensora ambiental.', 'jane.goodall@example.com'),
       ('Elon Musk', 'Empreendedor e inovador em tecnologia espacial.', 'elon.musk@example.com'),
       ('Sheryl Sandberg', 'Executiva e autora sobre liderança feminina.', 'sheryl.sandberg@example.com'),
       ('Prof. Stephen Hawking', 'Físico teórico e cosmólogo renomado.', 'stephen.hawking@example.com'),
       ('Dra. Mae Jemison', 'Primeira astronauta afro-americana.', 'mae.jemison@example.com'),
       ('Bill Gates', 'Cofundador da Microsoft e filantropo.', 'bill.gates@example.com'),
       ('Malala Yousafzai', 'Ativista pela educação e Nobel da Paz.', 'malala.yousafzai@example.com'),
       ('Dr. Neil deGrasse Tyson', 'Astrofísico e comunicador científico.', 'neil.tyson@example.com'),
       ('Dra. Katherine Johnson', 'Matemática da NASA pioneira em cálculos orbitais.', 'katherine.johnson@example.com'),
       ('Mark Zuckerberg', 'Fundador do Facebook e empreendedor tech.', 'mark.zuckerberg@example.com'),
       ('Dra. Chien-Shiung Wu', 'Física experimental pioneira.', 'chien.wu@example.com'),
       ('Larry Page', 'Cofundador do Google e cientista da computação.', 'larry.page@example.com'),
       ('Dra. Rachel Carson', 'Bióloga marinha e ambientalista.', 'rachel.carson@example.com'),
       ('Jeff Bezos', 'Fundador da Amazon e empreendedor.', 'jeff.bezos@example.com'),
       ('Dra. Barbara McClintock', 'Geneticista e Nobel de Medicina.', 'barbara.mcclintock@example.com'),
       ('Jack Dorsey', 'Cofundador do Twitter e Square.', 'jack.dorsey@example.com'),
       ('Dra. Rosalind Franklin', 'Biofísica pioneira no estudo do DNA.', 'rosalind.franklin@example.com'),
       ('Sundar Pichai', 'CEO do Google e Alphabet.', 'sundar.pichai@example.com'),
       ('Dra. Sally Ride', 'Primeira astronauta americana no espaço.', 'sally.ride@example.com'),
       ('Prof. Yuval Noah Harari', 'Historiador e autor de Sapiens.', 'yuval.harari@example.com'),
       ('Dra. Françoise Barré-Sinoussi', 'Virologista e Nobel de Medicina.', 'francoise.barre@example.com'),
       ('Satya Nadella', 'CEO da Microsoft.', 'satya.nadella@example.com'),
       ('Dra. Christiane Nüsslein-Volhard', 'Bióloga e Nobel de Medicina.', 'christiane.nusslein@example.com'),
       ('Reed Hastings', 'Cofundador e ex-CEO da Netflix.', 'reed.hastings@example.com'),
       ('Dra. Elizabeth Blackburn', 'Bióloga molecular e Nobel de Medicina.', 'elizabeth.blackburn@example.com'),
       ('Travis Kalanick', 'Cofundador do Uber.', 'travis.kalanick@example.com'),
       ('Dra. Jennifer Doudna', 'Bioquímica e Nobel de Química (CRISPR).', 'jennifer.doudna@example.com'),
       ('Daniel Ek', 'Fundador e CEO do Spotify.', 'daniel.ek@example.com'),
       ('Dra. Fabiola Gianotti', 'Física de partículas e diretora do CERN.', 'fabiola.gianotti@example.com'),
       ('Brian Chesky', 'Cofundador e CEO do Airbnb.', 'brian.chesky@example.com'),
       ('Dra. Tu Youyou', 'Farmacêutica e Nobel de Medicina.', 'tu.youyou@example.com'),
       ('Jan Koum', 'Cofundador do WhatsApp.', 'jan.koum@example.com'),
       ('Dra. Maryam Mirzakhani', 'Matemática e Medalha Fields.', 'maryam.mirzakhani@example.com'),
       ('Kevin Systrom', 'Cofundador do Instagram.', 'kevin.systrom@example.com'),
       ('Dra. Jocelyn Bell Burnell', 'Astrofísica descobridora dos pulsares.', 'jocelyn.bell@example.com'),
       ('Drew Houston', 'Fundador e CEO do Dropbox.', 'drew.houston@example.com'),
       ('Dra. Andrea Ghez', 'Astrofísica e Nobel de Física.', 'andrea.ghez@example.com'),
       ('Patrick Collison', 'Cofundador e CEO do Stripe.', 'patrick.collison@example.com');

-- QUALIFICATIONS - 50 PALESTRANTES
INSERT INTO speaker_qualifications (speaker_id, title_name, institution)
VALUES (1, 'Doutorado em Matemática', 'University of Cambridge'),
       (2, 'Nobel de Química', 'Sorbonne University'),
       (3, 'PHD em Matemática', 'Yale University'),
       (4, 'Engenheiro Elétrico', 'Graz University of Technology'),
       (5, 'Especialista em Algoritmos', 'University of London'),
       (6, 'Doutorado em Física', 'Princeton University'),
       (7, 'Especialista em Software de Sistemas', 'MIT'),
       (8, 'Doutorado em Astrofísica', 'University of Chicago'),
       (9, 'Inventora de Espectro de Difusão', 'National Inventors Hall of Fame'),
       (10, 'Engenheiro de Computação', 'UC Berkeley'),
       (11, 'Doutorado em Ciência da Computação', 'University of Oxford'),
       (12, 'Mestrado em Ciência da Computação', 'University of Helsinki'),
       (13, 'Doutorado em Etologia', 'University of Cambridge'),
       (14, 'Bacharel em Física', 'University of Pennsylvania'),
       (15, 'MBA', 'Harvard Business School'),
       (16, 'Doutorado em Física Teórica', 'University of Cambridge'),
       (17, 'Doutorado em Engenharia Química', 'Stanford University'),
       (18, 'Bacharel em Ciência da Computação', 'Harvard University'),
       (19, 'Nobel da Paz', 'University of Oxford'),
       (20, 'Doutorado em Astrofísica', 'Columbia University'),
       (21, 'Mestrado em Matemática', 'West Virginia University'),
       (22, 'Bacharel em Ciência da Computação', 'Harvard University'),
       (23, 'Doutorado em Física', 'UC Berkeley'),
       (24, 'Mestrado em Ciência da Computação', 'Stanford University'),
       (25, 'Mestrado em Biologia Marinha', 'Johns Hopkins University'),
       (26, 'Bacharel em Engenharia Elétrica', 'Princeton University'),
       (27, 'Doutorado em Genética', 'Cornell University'),
       (28, 'Bacharel em Ciência da Computação', 'New York University'),
       (29, 'Doutorado em Química Física', 'King\s College London'),
       (30, 'Mestrado em Engenharia', 'Stanford University'),
       (31, 'Doutorado em Física', 'Stanford University'),
       (32, 'Doutorado em História', 'University of Oxford'),
       (33, 'Doutorado em Virologia', 'Institut Pasteur'),
       (34, 'Mestrado em Ciência da Computação', 'University of Wisconsin'),
       (35, 'Doutorado em Biologia', 'University of Tübingen'),
       (36, 'Mestrado em Engenharia Elétrica', 'Stanford University'),
       (37, 'Doutorado em Biologia Molecular', 'University of California'),
       (38, 'Bacharel em Engenharia Civil', 'UCLA'),
       (39, 'Doutorado em Bioquímica', 'Harvard University'),
       (40, 'Engenheiro de Software', 'Royal Institute of Technology'),
       (41, 'Doutorado em Física de Partículas', 'University of Milan'),
       (42, 'Bacharel em Ciência da Computação', 'Harvard University'),
       (43, 'Doutorado em Farmácia', 'Pequim Medical University'),
       (44, 'Mestrado em Ciência da Computação', 'San Jose State University'),
       (45, 'Doutorado em Matemática', 'Harvard University'),
       (46, 'Mestrado em Engenharia', 'Stanford University'),
       (47, 'Doutorado em Física', 'University of Glasgow'),
       (48, 'Bacharel em Ciência da Computação', 'MIT'),
       (49, 'Doutorado em Física', 'Caltech'),
       (50, 'Bacharel em Física', 'MIT');

-- Insert 50 organizers
INSERT INTO public.organizers (id, name, contact_email)
VALUES ('a1111111-1111-1111-1111-111111111111', 'Departamento de Ciências da Computação', 'cs.dept@university.edu'),
       ('a2222222-2222-2222-2222-222222222222', 'Centro Estudantil de Atividades', 'student.activities@university.edu'),
       ('a3333333-3333-3333-3333-333333333333', 'Instituto de Pesquisa Ambiental',
        'environmental.research@university.edu'),
       ('a4444444-4444-4444-4444-444444444444', 'Serviços de Carreira e Desenvolvimento',
        'career.services@university.edu'),
       ('a5555555-5555-5555-5555-555555555555', 'Departamento de Estudos Culturais', 'cultural.studies@university.edu'),
       ('a6666666-6666-6666-6666-666666666666', 'Departamento de Engenharia Elétrica', 'ee.dept@university.edu'),
       ('a7777777-7777-7777-7777-777777777777', 'Centro de Inovação e Empreendedorismo',
        'innovation.center@university.edu'),
       ('a8888888-8888-8888-8888-888888888888', 'Departamento de Matemática', 'math.dept@university.edu'),
       ('a9999999-9999-9999-9999-999999999999', 'Laboratório de Inteligência Artificial', 'ai.lab@university.edu'),
       ('b1111111-1111-1111-1111-111111111111', 'Centro de Pesquisa em Blockchain',
        'blockchain.research@university.edu'),
       ('b2222222-2222-2222-2222-222222222222', 'Departamento de Design e Artes', 'design.arts@university.edu'),
       ('b3333333-3333-3333-3333-333333333333', 'Núcleo de Estudos em Sustentabilidade',
        'sustainability@university.edu'),
       ('b4444444-4444-4444-4444-444444444444', 'Departamento de Física', 'physics.dept@university.edu'),
       ('b5555555-5555-5555-5555-555555555555', 'Centro de Saúde Mental e Bem-Estar', 'mental.health@university.edu'),
       ('b6666666-6666-6666-6666-666666666666', 'Departamento de Química', 'chemistry.dept@university.edu'),
       ('b7777777-7777-7777-7777-777777777777', 'Grupo de Estudos em Criptomoedas', 'crypto.group@university.edu'),
       ('b8888888-8888-8888-8888-888888888888', 'Departamento de Administração', 'business.admin@university.edu'),
       ('b9999999-9999-9999-9999-999999999999', 'Centro de Tecnologias Educacionais', 'edtech.center@university.edu'),
       ('c1111111-1111-1111-1111-111111111111', 'Departamento de Biologia', 'biology.dept@university.edu'),
       ('c2222222-2222-2222-2222-222222222222', 'Núcleo de Marketing Digital', 'digital.marketing@university.edu'),
       ('c3333333-3333-3333-3333-333333333333', 'Departamento de Engenharia Civil', 'civil.eng@university.edu'),
       ('c4444444-4444-4444-4444-444444444444', 'Centro de Estudos Musicais', 'music.studies@university.edu'),
       ('c5555555-5555-5555-5555-555555555555', 'Laboratório de Robótica', 'robotics.lab@university.edu'),
       ('c6666666-6666-6666-6666-666666666666', 'Departamento de Psicologia', 'psychology.dept@university.edu'),
       ('c7777777-7777-7777-7777-777777777777', 'Centro de Desenvolvimento Web', 'web.dev@university.edu'),
       ('c8888888-8888-8888-8888-888888888888', 'Departamento de Economia', 'economics.dept@university.edu'),
       ('c9999999-9999-9999-9999-999999999999', 'Núcleo de Estudos em Dados e Analytics',
        'data.analytics@university.edu'),
       ('d1111111-1111-1111-1111-111111111111', 'Departamento de Arquitetura', 'architecture.dept@university.edu'),
       ('d2222222-2222-2222-2222-222222222222', 'Centro de Segurança da Informação', 'infosec.center@university.edu'),
       ('d3333333-3333-3333-3333-333333333333', 'Departamento de Literatura', 'literature.dept@university.edu'),
       ('d4444444-4444-4444-4444-444444444444', 'Grupo de Desenvolvimento Mobile', 'mobile.dev@university.edu'),
       ('d5555555-5555-5555-5555-555555555555', 'Departamento de Direito', 'law.dept@university.edu'),
       ('d6666666-6666-6666-6666-666666666666', 'Centro de Cloud Computing', 'cloud.center@university.edu'),
       ('d7777777-7777-7777-7777-777777777777', 'Departamento de Educação Física', 'sports.dept@university.edu'),
       ('d8888888-8888-8888-8888-888888888888', 'Núcleo de Soft Skills e Liderança',
        'softskills.leadership@university.edu'),
       ('d9999999-9999-9999-9999-999999999999', 'Departamento de Cinema e Audiovisual', 'cinema.dept@university.edu'),
       ('e1111111-1111-1111-1111-111111111111', 'Centro de Fotografia Digital', 'photography.center@university.edu'),
       ('e2222222-2222-2222-2222-222222222222', 'Departamento de Engenharia Mecânica', 'mech.eng@university.edu'),
       ('e3333333-3333-3333-3333-333333333333', 'Grupo de Estudos em IoT', 'iot.group@university.edu'),
       ('e4444444-4444-4444-4444-444444444444', 'Departamento de Filosofia', 'philosophy.dept@university.edu'),
       ('e5555555-5555-5555-5555-555555555555', 'Centro de DevOps e Automação', 'devops.center@university.edu'),
       ('e6666666-6666-6666-6666-666666666666', 'Departamento de Jornalismo', 'journalism.dept@university.edu'),
       ('e7777777-7777-7777-7777-777777777777', 'Núcleo de UX e UI Design', 'uxui.design@university.edu'),
       ('e8888888-8888-8888-8888-888888888888', 'Departamento de Medicina', 'medicine.dept@university.edu'),
       ('e9999999-9999-9999-9999-999999999999', 'Centro de Machine Learning', 'ml.center@university.edu'),
       ('f1111111-1111-1111-1111-111111111111', 'Departamento de Turismo', 'tourism.dept@university.edu'),
       ('f2222222-2222-2222-2222-222222222222', 'Grupo de Desenvolvimento de Jogos', 'gamedev.group@university.edu'),
       ('f3333333-3333-3333-3333-333333333333', 'Departamento de Nutrição', 'nutrition.dept@university.edu'),
       ('f4444444-4444-4444-4444-444444444444', 'Centro de Big Data', 'bigdata.center@university.edu'),
       ('f5555555-5555-5555-5555-555555555555', 'Departamento de Relações Internacionais',
        'international.relations@university.edu');

--  LOCALIZAÇÕES
INSERT INTO public.locations (name, street, number, neighborhood, city, state, zip_code, campus, reference_point,
                              capacity)
VALUES ('Laboratório de Informática 01', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000',
        'Campus Surubim Central', 'Prédio Principal', 40),
       ('Sala de Aula 101', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Campus Surubim Norte',
        'Bloco A', 50),
       ('Sala de Aula 102', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Campus Surubim Leste',
        'Bloco A', 50),
       ('Sala de Aula 103', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Campus Surubim Sul',
        'Bloco A', 50),
       ('Sala de Aula 104', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Campus Surubim Oeste',
        'Bloco A', 50),
       ('Sala de Aula 201', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Campus Surubim Alfa',
        'Bloco B', 60),
       ('Sala de Aula 202', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Campus Surubim Beta',
        'Bloco B', 60),
       ('Laboratório de Química', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000',
        'Campus Surubim Gama', 'Prédio de Ciências', 30),
       ('Laboratório de Física', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000',
        'Campus Surubim Central', 'Prédio de Ciências', 30),
       ('Laboratório de Biologia', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000',
        'Campus Surubim Norte', 'Prédio de Ciências', 35),
       ('Auditório Principal', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Campus Surubim Sul',
        'Térreo', 250),
       ('Mini Auditório', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Campus Surubim Leste',
        'Bloco C', 80),
       ('Biblioteca Central', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Campus Surubim Oeste',
        'Prédio Anexo', 150),
       ('Sala de Estudos 01', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Campus Surubim Alfa',
        'Dentro da Biblioteca', 20),
       ('Sala de Estudos 02', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Campus Surubim Beta',
        'Dentro da Biblioteca', 20),
       ('Sala de Reuniões Coordenação', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000',
        'Campus Surubim Gama', 'Prédio Administrativo', 15),
       ('Quadra Poliesportiva', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000',
        'Campus Surubim Central', 'Área Externa', 500),
       ('Espaço Maker', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000', 'Campus Surubim Inovação',
        'Prédio de Inovação', 45),
       ('Estúdio de Gravação', 'Rua das Flores', '123', 'Centro', 'Surubim', 'PE', '55750-000',
        'Campus Surubim Criativo', 'Prédio de Comunicação', 10),
       ('Laboratório de Redes', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000',
        'Campus Recife Norte', 'Bloco 1', 40),
       ('Laboratório de Hardware', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000',
        'Campus Recife Leste', 'Bloco 1', 35),
       ('Sala de Aula 301', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife Sul',
        'Bloco 2', 55),
       ('Sala de Aula 302', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000',
        'Campus Recife Oeste', 'Bloco 2', 55),
       ('Sala de Aula 303', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000',
        'Campus Recife Central', 'Bloco 2', 55),
       ('Auditório Paulo Freire', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000',
        'Campus Recife Alfa', 'Térreo', 300),
       ('Sala de Videoconferência', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000',
        'Campus Recife Beta', 'Bloco 1', 25),
       ('Laboratório de Robótica', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000',
        'Campus Recife Gama', 'Bloco 3', 30),
       ('Sala de Metodologias Ativas 1', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000',
        'Campus Recife Inovação', 'Bloco 3', 40),
       ('Sala de Metodologias Ativas 2', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000',
        'Campus Recife Criativo', 'Bloco 3', 40),
       ('Biblioteca Setorial', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000',
        'Campus Recife Central', 'Bloco 4', 100),
       ('Laboratório de Enfermagem', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000',
        'Campus Recife Saúde', 'Bloco Saúde', 30),
       ('Laboratório de Anatomia', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000',
        'Campus Recife Saúde', 'Bloco Saúde', 40),
       ('Clínica Escola', 'Av. Agamenon Magalhães', 'S/N', 'Derby', 'Recife', 'PE', '52010-000', 'Campus Recife Saúde',
        'Bloco Saúde', 50),
       ('Sala de Aula 401', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Leste', 'Bloco A', 60),
       ('Sala de Aula 402', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Sul', 'Bloco A', 60),
       ('Sala de Aula 403', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Oeste', 'Bloco A', 60),
       ('Laboratório de Design', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Criativo', 'Bloco B', 35),
       ('Laboratório de Moda', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Criativo', 'Bloco B', 30),
       ('Ateliê de Costura', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Criativo', 'Bloco B', 25),
       ('Sala de Desenho', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Alfa', 'Bloco B', 40),
       ('Auditório Ariano Suassuna', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Central', 'Central', 200),
       ('Laboratório de Informática 03', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Beta', 'Bloco C', 40),
       ('Laboratório de Informática 04', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Gama', 'Bloco C', 40),
       ('Sala de Reuniões Professores', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Delta', 'Administrativo', 20),
       ('Espaço de Convivência', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Central', 'Externo', 150),
       ('Laboratório de Fotografia', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Inovação', 'Bloco D', 20),
       ('Estúdio de Áudio', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Inovação', 'Bloco D', 15),
       ('Sala de Defesas', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Pós-Graduação', 'Bloco Pós', 35),
       ('Laboratório Maker Avançado', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Inovação', 'Inovação', 40),
       ('Laboratório Maker Intermediário', 'Rodovia BR-104', 'Km 68', 'Nova Caruaru', 'Caruaru', 'PE', '55014-000',
        'Campus Caruaru Inovação', 'Inovação', 40);


-- 50 EVENTOS (Com variação de datas, status, organizadores, categorias e locais)
INSERT INTO public.events (id, organizer_id, category_id, location_id, title, description, online_link, start_time,
                           end_time, workload_hours, max_capacity, status, created_at)
VALUES ('e153c21a-d628-46ef-b838-b66d4758b966', 'a1111111-1111-1111-1111-111111111111', 2, 1,
        'Inteligência Artificial e o Futuro do Trabalho',
        'Junte-se a nós para uma palestra esclarecedora sobre como a IA está transformando o local de trabalho...',
        'https://example.com/ia-futuro-trabalho', '2026-02-20 14:00:00.000000', '2026-02-20 16:00:00.000000', 2, 200,
        'ACTIVE', NOW()),

       ('e2222222-d628-46ef-b838-b66d4758b966', 'a5555555-5555-5555-5555-555555555555', 4, 18,
        'Festival Cultural Internacional 2026',
        'Experimente uma celebração da diversidade com apresentações, comida e exposições de mais de 30 países...',
        NULL, '2026-03-15 10:00:00.000000', '2026-03-15 18:00:00.000000', 8, 1000, 'ACTIVE', NOW()),

       ('e3333333-d628-46ef-b838-b66d4758b966', 'a3333333-3333-3333-3333-333333333333', 3, 26,
        'Mudanças Climáticas: Ciência e Ação',
        'Uma série abrangente de seminários com os principais cientistas climáticos e ativistas ambientais...',
        'https://example.com/mudancas-climaticas', '2026-02-28 09:00:00.000000', '2026-02-28 13:00:00.000000', 4, 100,
        'ACTIVE', NOW()),

       ('e4444444-d628-46ef-b838-b66d4758b966', 'a4444444-4444-4444-4444-444444444444', 5, 42,
        'Feira de Carreiras 2026: Tecnologia e Inovação',
        'Encontre-se com representantes de mais de 50 empresas líderes em tecnologia...',
        'https://example.com/feira-carreiras', '2026-03-05 11:00:00.000000', '2026-03-05 17:00:00.000000', 6, 500,
        'ACTIVE', NOW()),

       ('e5555555-d628-46ef-b838-b66d4758b966', 'a2222222-2222-2222-2222-222222222222', 6, 13,
        'Workshop de Estratégias de Marketing Digital',
        'Workshop prático cobrindo marketing em mídias sociais, SEO, criação de conteúdo e análise de dados...',
        'https://example.com/workshop-marketing', '2026-02-25 15:00:00.000000', '2026-02-25 18:00:00.000000', 3, 50,
        'ACTIVE', NOW()),

       ('e6666666-d628-46ef-b838-b66d4758b966', 'a2222222-2222-2222-2222-222222222222', 3, 17,
        'Seminário de Saúde Mental e Bem-Estar',
        'Uma discussão importante sobre saúde mental estudantil, técnicas de gerenciamento de estresse...',
        'https://example.com/saude-mental', '2026-02-18 16:00:00.000000', '2026-02-18 18:00:00.000000', 2, 80,
        'ACTIVE', NOW()),

       ('e7777777-d628-46ef-b838-b66d4758b966', 'a5555555-5555-5555-5555-555555555555', 4, 12,
        'Noite de Rock na Universidade',
        'Desfrute de uma noite de música rock ao vivo apresentada pelo Conjunto de Pseudo Músicos...',
        'https://example.com/noite-rock', '2026-03-10 19:00:00.000000', '2026-03-10 21:30:00.000000', 2.5, 250,
        'CANCELLED', NOW()),

       ('e8888888-d628-46ef-b838-b66d4758b966', 'a1111111-1111-1111-1111-111111111111', 8, 19,
        'Conferência sobre Blockchain e Criptomoedas',
        'Explore o mundo da tecnologia blockchain, mercados de criptomoedas e finanças descentralizadas...',
        'https://example.com/conferencia-blockchain', '2026-03-22 10:00:00.000000', '2026-03-22 16:00:00.000000', 6,
        150,
        'ACTIVE', NOW()),

-- Novos eventos (9-50)
       ('e9999999-d628-46ef-b838-b66d4758b966', 'a6666666-6666-6666-6666-666666666666', 1, 5,
        'Introdução à Engenharia Elétrica',
        'Workshop introdutório sobre conceitos fundamentais de circuitos elétricos e sistemas de potência...',
        'https://example.com/intro-eng-eletrica', '2025-12-10 09:00:00.000000', '2025-12-10 12:00:00.000000', 3, 60,
        'COMPLETED', NOW()),

       ('f1111111-d628-46ef-b838-b66d4758b966', 'a7777777-7777-7777-7777-777777777777', 2, 8,
        'Hackathon de Inovação 2025',
        'Evento de 24 horas para desenvolvimento de soluções inovadoras em equipe...',
        NULL, '2025-11-15 18:00:00.000000', '2025-11-16 18:00:00.000000', 24, 100,
        'COMPLETED', NOW()),

       ('f2222222-d628-46ef-b838-b66d4758b966', 'a8888888-8888-8888-8888-888888888888', 7, 3,
        'Olimpíada de Matemática Aplicada',
        'Competição de resolução de problemas matemáticos complexos para estudantes...',
        'https://example.com/olimpiada-matematica', '2026-04-10 08:00:00.000000', '2026-04-10 17:00:00.000000', 9, 150,
        'ACTIVE', NOW()),

       ('f3333333-d628-46ef-b838-b66d4758b966', 'a9999999-9999-9999-9999-999999999999', 2, 7,
        'Deep Learning na Prática',
        'Workshop avançado sobre redes neurais profundas e aplicações práticas...',
        'https://example.com/deep-learning', '2026-03-18 14:00:00.000000', '2026-03-18 18:00:00.000000', 4, 40,
        'ACTIVE', NOW()),

       ('f4444444-d628-46ef-b838-b66d4758b966', 'b1111111-1111-1111-1111-111111111111', 8, 11,
        'Smart Contracts e DeFi',
        'Aprenda a desenvolver contratos inteligentes na blockchain Ethereum...',
        'https://example.com/smart-contracts', '2026-02-28 10:00:00.000000', '2026-02-28 16:00:00.000000', 6, 80,
        'ACTIVE', NOW()),

       ('f5555555-d628-46ef-b838-b66d4758b966', 'b2222222-2222-2222-2222-222222222222', 4, 14,
        'Exposição de Arte Digital Contemporânea',
        'Mostra de trabalhos digitais de estudantes e artistas convidados...',
        NULL, '2026-03-20 10:00:00.000000', '2026-03-22 20:00:00.000000', 30, 300,
        'ACTIVE', NOW()),

       ('f6666666-d628-46ef-b838-b66d4758b966', 'b3333333-3333-3333-3333-333333333333', 3, 26,
        'Economia Circular e Sustentabilidade',
        'Discussão sobre práticas sustentáveis e modelos de economia circular...',
        'https://example.com/economia-circular', '2025-10-05 15:00:00.000000', '2025-10-05 18:00:00.000000', 3, 120,
        'COMPLETED', NOW()),

       ('f7777777-d628-46ef-b838-b66d4758b966', 'b4444444-4444-4444-4444-444444444444', 7, 2,
        'Física Quântica para Iniciantes',
        'Introdução aos conceitos fundamentais da mecânica quântica...',
        'https://example.com/fisica-quantica', '2026-04-15 09:00:00.000000', '2026-04-15 12:00:00.000000', 3, 100,
        'ACTIVE', NOW()),

       ('f8888888-d628-46ef-b838-b66d4758b966', 'b5555555-5555-5555-5555-555555555555', 3, 17,
        'Mindfulness e Produtividade',
        'Workshop sobre técnicas de mindfulness para melhorar foco e produtividade...',
        NULL, '2026-03-08 14:00:00.000000', '2026-03-08 17:00:00.000000', 3, 50,
        'ACTIVE', NOW()),

       ('f9999999-d628-46ef-b838-b66d4758b966', 'b6666666-6666-6666-6666-666666666666', 7, 4,
        'Química Orgânica Avançada',
        'Seminário sobre síntese e análise de compostos orgânicos complexos...',
        'https://example.com/quimica-organica', '2025-09-20 10:00:00.000000', '2025-09-20 13:00:00.000000', 3, 70,
        'COMPLETED', NOW()),

       ('11111111-d628-46ef-b838-b66d4758b966', 'b7777777-7777-7777-7777-777777777777', 8, 9,
        'Investindo em Criptomoedas com Segurança',
        'Aprenda estratégias seguras para investimento em ativos digitais...',
        'https://example.com/invest-crypto', '2026-02-22 15:00:00.000000', '2026-02-22 18:00:00.000000', 3, 90,
        'ACTIVE', NOW()),

       ('12222222-d628-46ef-b838-b66d4758b966', 'b8888888-8888-8888-8888-888888888888', 5, 42,
        'Empreendedorismo e Gestão de Startups',
        'Palestra com empreendedores de sucesso sobre criação e gestão de startups...',
        'https://example.com/empreendedorismo', '2026-03-12 13:00:00.000000', '2026-03-12 17:00:00.000000', 4, 200,
        'ACTIVE', NOW()),

       ('13333333-d628-46ef-b838-b66d4758b966', 'b9999999-9999-9999-9999-999999999999', 2, 6,
        'Realidade Virtual na Educação',
        'Demonstração de aplicações de VR e AR no ensino e treinamento...',
        NULL, '2026-04-05 10:00:00.000000', '2026-04-05 14:00:00.000000', 4, 60,
        'ACTIVE', NOW()),

       ('14444444-d628-46ef-b838-b66d4758b966', 'c1111111-1111-1111-1111-111111111111', 7, 20,
        'Biotecnologia e Genética Molecular',
        'Conferência sobre avanços recentes em edição genética e terapias...',
        'https://example.com/biotecnologia', '2025-08-15 09:00:00.000000', '2025-08-15 16:00:00.000000', 7, 110,
        'COMPLETED', NOW()),

       ('15555555-d628-46ef-b838-b66d4758b966', 'c2222222-2222-2222-2222-222222222222', 6, 13,
        'Growth Hacking para Startups',
        'Técnicas avançadas de marketing para crescimento acelerado...',
        'https://example.com/growth-hacking', '2026-03-25 14:00:00.000000', '2026-03-25 18:00:00.000000', 4, 70,
        'ACTIVE', NOW()),

       ('16666666-d628-46ef-b838-b66d4758b966', 'c3333333-3333-3333-3333-333333333333', 1, 21,
        'BIM na Construção Civil',
        'Workshop sobre modelagem de informação da construção com Revit...',
        'https://example.com/bim-construcao', '2026-04-18 08:00:00.000000', '2026-04-18 17:00:00.000000', 9, 45,
        'ACTIVE', NOW()),

       ('17777777-d628-46ef-b838-b66d4758b966', 'c4444444-4444-4444-4444-444444444444', 4, 12,
        'Festival de Jazz Universitário',
        'Apresentações de grupos de jazz estudantis e artistas convidados...',
        NULL, '2026-03-28 19:00:00.000000', '2026-03-28 23:00:00.000000', 4, 400,
        'ACTIVE', NOW()),

       ('18888888-d628-46ef-b838-b66d4758b966', 'c5555555-5555-5555-5555-555555555555', 2, 15,
        'Robótica Colaborativa na Indústria 4.0',
        'Demonstração de robôs colaborativos e aplicações industriais...',
        'https://example.com/robotica-colaborativa', '2025-07-10 10:00:00.000000', '2025-07-10 15:00:00.000000', 5, 80,
        'COMPLETED', NOW()),

       ('19999999-d628-46ef-b838-b66d4758b966', 'c6666666-6666-6666-6666-666666666666', 3, 17,
        'Psicologia Positiva e Felicidade',
        'Seminário sobre ciência da felicidade e bem-estar psicológico...',
        'https://example.com/psicologia-positiva', '2026-02-15 14:00:00.000000', '2026-02-15 17:00:00.000000', 3, 100,
        'ACTIVE', NOW()),

       ('21111111-d628-46ef-b838-b66d4758b966', 'c7777777-7777-7777-7777-777777777777', 2, 10,
        'Desenvolvimento Full Stack com React e Node',
        'Bootcamp intensivo de desenvolvimento web moderno...',
        'https://example.com/fullstack-bootcamp', '2026-04-20 09:00:00.000000', '2026-04-24 18:00:00.000000', 40, 30,
        'ACTIVE', NOW()),

       ('22222222-d628-46ef-b838-b66d4758b966', 'c8888888-8888-8888-8888-888888888888', 5, 42,
        'Finanças Pessoais para Jovens Profissionais',
        'Workshop sobre planejamento financeiro, investimentos e aposentadoria...',
        'https://example.com/financas-pessoais', '2026-03-07 10:00:00.000000', '2026-03-07 13:00:00.000000', 3, 150,
        'ACTIVE', NOW()),

       ('23333333-d628-46ef-b838-b66d4758b966', 'c9999999-9999-9999-9999-999999999999', 2, 16,
        'Big Data e Analytics com Python',
        'Curso prático sobre análise de grandes volumes de dados...',
        'https://example.com/bigdata-python', '2025-06-05 13:00:00.000000', '2025-06-07 18:00:00.000000', 15, 50,
        'COMPLETED', NOW()),

       ('24444444-d628-46ef-b838-b66d4758b966', 'd1111111-1111-1111-1111-111111111111', 4, 22,
        'Arquitetura Sustentável e Bioclimática',
        'Palestra sobre design arquitetônico eco-friendly...',
        NULL, '2026-04-12 14:00:00.000000', '2026-04-12 17:00:00.000000', 3, 90,
        'ACTIVE', NOW()),

       ('25555555-d628-46ef-b838-b66d4758b966', 'd2222222-2222-2222-2222-222222222222', 2, 23,
        'Segurança Cibernética e Ethical Hacking',
        'Workshop sobre testes de penetração e defesa de sistemas...',
        'https://example.com/ethical-hacking', '2026-03-30 09:00:00.000000', '2026-03-30 18:00:00.000000', 9, 40,
        'ACTIVE', NOW()),

       ('26666666-d628-46ef-b838-b66d4758b966', 'd3333333-3333-3333-3333-333333333333', 4, 24,
        'Sarau Literário - Poesia Contemporânea',
        'Noite de leitura e discussão de poesia contemporânea brasileira...',
        NULL, '2026-03-17 19:00:00.000000', '2026-03-17 22:00:00.000000', 3, 80,
        'ACTIVE', NOW()),

       ('27777777-d628-46ef-b838-b66d4758b966', 'd4444444-4444-4444-4444-444444444444', 2, 25,
        'Flutter: Desenvolvimento Mobile Multiplataforma',
        'Curso sobre criação de apps iOS e Android com Flutter...',
        'https://example.com/flutter-mobile', '2025-05-10 10:00:00.000000', '2025-05-12 17:00:00.000000', 21, 35,
        'COMPLETED', NOW()),

       ('28888888-d628-46ef-b838-b66d4758b966', 'd5555555-5555-5555-5555-555555555555', 5, 27,
        'Direito Digital e LGPD',
        'Seminário sobre legislação de proteção de dados e compliance...',
        'https://example.com/direito-digital', '2026-02-26 14:00:00.000000', '2026-02-26 18:00:00.000000', 4, 120,
        'ACTIVE', NOW()),

       ('29999999-d628-46ef-b838-b66d4758b966', 'd6666666-6666-6666-6666-666666666666', 2, 28,
        'Kubernetes e Orquestração de Containers',
        'Workshop sobre deploy e gestão de aplicações em nuvem...',
        'https://example.com/kubernetes', '2026-04-08 09:00:00.000000', '2026-04-08 17:00:00.000000', 8, 50,
        'ACTIVE', NOW()),

       ('31111111-d628-46ef-b838-b66d4758b966', 'd7777777-7777-7777-7777-777777777777', 3, 29,
        'Treinamento Funcional e Performance',
        'Workshop sobre técnicas de treinamento para atletas...',
        NULL, '2026-03-14 07:00:00.000000', '2026-03-14 10:00:00.000000', 3, 40,
        'ACTIVE', NOW()),

       ('32222222-d628-46ef-b838-b66d4758b966', 'd8888888-8888-8888-8888-888888888888', 3, 30,
        'Comunicação Não-Violenta no Trabalho',
        'Seminário sobre técnicas de comunicação empática e resolução de conflitos...',
        'https://example.com/comunicacao-nv', '2026-02-21 13:00:00.000000', '2026-02-21 16:00:00.000000', 3, 60,
        'ACTIVE', NOW()),

       ('33333333-d628-46ef-b838-b66d4758b966', 'd9999999-9999-9999-9999-999999999999', 4, 31,
        'Mostra de Curtas-Metragens Estudantis',
        'Exibição de filmes produzidos por estudantes de cinema...',
        NULL, '2026-04-25 18:00:00.000000', '2026-04-25 22:00:00.000000', 4, 200,
        'ACTIVE', NOW()),

       ('34444444-d628-46ef-b838-b66d4758b966', 'e1111111-1111-1111-1111-111111111111', 4, 32,
        'Fotografia de Retrato e Iluminação',
        'Workshop prático sobre técnicas de iluminação em estúdio...',
        'https://example.com/fotografia-retrato', '2025-04-15 09:00:00.000000', '2025-04-15 16:00:00.000000', 7, 25,
        'COMPLETED', NOW()),

       ('35555555-d628-46ef-b838-b66d4758b966', 'e2222222-2222-2222-2222-222222222222', 1, 33,
        'Manutenção Preditiva com IoT',
        'Conferência sobre sensores e análise preditiva na indústria...',
        'https://example.com/manutencao-iot', '2026-03-11 10:00:00.000000', '2026-03-11 16:00:00.000000', 6, 80,
        'ACTIVE', NOW()),

       ('36666666-d628-46ef-b838-b66d4758b966', 'e3333333-3333-3333-3333-333333333333', 2, 34,
        'IoT e Casas Inteligentes',
        'Workshop sobre automação residencial e dispositivos conectados...',
        NULL, '2026-04-02 14:00:00.000000', '2026-04-02 18:00:00.000000', 4, 55,
        'ACTIVE', NOW()),

       ('37777777-d628-46ef-b838-b66d4758b966', 'e4444444-4444-4444-4444-444444444444', 7, 35,
        'Filosofia da Tecnologia',
        'Discussão sobre implicações éticas e filosóficas da tecnologia moderna...',
        'https://example.com/filosofia-tech', '2026-02-19 15:00:00.000000', '2026-02-19 18:00:00.000000', 3, 70,
        'ACTIVE', NOW()),

       ('38888888-d628-46ef-b838-b66d4758b966', 'e5555555-5555-5555-5555-555555555555', 2, 36,
        'CI/CD com GitHub Actions',
        'Workshop sobre automação de deploy e integração contínua...',
        'https://example.com/cicd-github', '2025-03-20 13:00:00.000000', '2025-03-20 17:00:00.000000', 4, 45,
        'COMPLETED', NOW()),

       ('39999999-d628-46ef-b838-b66d4758b966', 'e6666666-6666-6666-6666-666666666666', 4, 37,
        'Jornalismo de Dados e Visualização',
        'Curso sobre storytelling com dados e ferramentas de visualização...',
        'https://example.com/jornalismo-dados', '2026-04-22 09:00:00.000000', '2026-04-23 17:00:00.000000', 16, 40,
        'ACTIVE', NOW()),

       ('41111111-d628-46ef-b838-b66d4758b966', 'e7777777-7777-7777-7777-777777777777', 2, 38,
        'Design Thinking e UX Research',
        'Workshop sobre metodologias de design centrado no usuário...',
        NULL, '2026-03-24 10:00:00.000000', '2026-03-24 17:00:00.000000', 7, 50,
        'ACTIVE', NOW()),

       ('42222222-d628-46ef-b838-b66d4758b966', 'e8888888-8888-8888-8888-888888888888', 3, 39,
        'Primeiros Socorros e Suporte Básico de Vida',
        'Treinamento prático de procedimentos de emergência médica...',
        'https://example.com/primeiros-socorros', '2026-02-27 08:00:00.000000', '2026-02-27 12:00:00.000000', 4, 30,
        'ACTIVE', NOW()),

       ('43333333-d628-46ef-b838-b66d4758b966', 'e9999999-9999-9999-9999-999999999999', 2, 40,
        'TensorFlow e Redes Neurais',
        'Curso avançado sobre deep learning com TensorFlow 2.0...',
        'https://example.com/tensorflow-nn', '2025-02-10 09:00:00.000000', '2025-02-14 18:00:00.000000', 40, 35,
        'COMPLETED', NOW()),

       ('44444444-d628-46ef-b838-b66d4758b966', 'f1111111-1111-1111-1111-111111111111', 5, 41,
        'Turismo Sustentável e Ecoturismo',
        'Palestra sobre práticas sustentáveis no setor turístico...',
        NULL, '2026-04-16 14:00:00.000000', '2026-04-16 17:00:00.000000', 3, 100,
        'ACTIVE', NOW()),

       ('45555555-d628-46ef-b838-b66d4758b966', 'f2222222-2222-2222-2222-222222222222', 4, 43,
        'Game Jam 48h - Desenvolvimento de Jogos',
        'Competição de criação de jogos em 48 horas...',
        'https://example.com/game-jam', '2026-04-26 18:00:00.000000', '2026-04-28 18:00:00.000000', 48, 60,
        'ACTIVE', NOW()),

       ('46666666-d628-46ef-b838-b66d4758b966', 'f3333333-3333-3333-3333-333333333333', 3, 44,
        'Nutrição Esportiva para Atletas',
        'Workshop sobre dieta e suplementação para performance...',
        'https://example.com/nutricao-esportiva', '2026-03-13 10:00:00.000000', '2026-03-13 13:00:00.000000', 3, 50,
        'ACTIVE', NOW()),

       ('47777777-d628-46ef-b838-b66d4758b966', 'f4444444-4444-4444-4444-444444444444', 2, 45,
        'Apache Spark e Processamento Distribuído',
        'Curso sobre processamento de big data em larga escala...',
        'https://example.com/apache-spark', '2025-01-15 09:00:00.000000', '2025-01-17 17:00:00.000000', 24, 40,
        'COMPLETED', NOW()),

       ('48888888-d628-46ef-b838-b66d4758b966', 'f5555555-5555-5555-5555-555555555555', 5, 46,
        'Diplomacia e Negociação Internacional',
        'Seminário sobre relações internacionais e técnicas de negociação...',
        NULL, '2026-04-09 13:00:00.000000', '2026-04-09 18:00:00.000000', 5, 80,
        'ACTIVE', NOW());


-- Insert event tags para os 50 eventos
INSERT INTO public.event_tags (event_id, tag_id)
VALUES ('e153c21a-d628-46ef-b838-b66d4758b966', 5),  -- carreira -- Evento 1 (Inteligência Artificial)
       ('e153c21a-d628-46ef-b838-b66d4758b966', 16), -- ia
       ('e153c21a-d628-46ef-b838-b66d4758b966', 17), -- inovação
       ('e153c21a-d628-46ef-b838-b66d4758b966', 28), -- tecnologia

-- Evento 2 (Festival Cultural)
       ('e2222222-d628-46ef-b838-b66d4758b966', 9),  -- cultura
       ('e2222222-d628-46ef-b838-b66d4758b966', 11), -- diversidade
       ('e2222222-d628-46ef-b838-b66d4758b966', 14), -- festival
       ('e2222222-d628-46ef-b838-b66d4758b966', 18), -- internacional

-- Evento 3 (Mudanças Climáticas)
       ('e3333333-d628-46ef-b838-b66d4758b966', 6),  -- ciência
       ('e3333333-d628-46ef-b838-b66d4758b966', 7),  -- clima
       ('e3333333-d628-46ef-b838-b66d4758b966', 20), -- meio ambiente
       ('e3333333-d628-46ef-b838-b66d4758b966', 27), -- sustentabilidade

-- Evento 4 (Feira de Carreiras)
       ('e4444444-d628-46ef-b838-b66d4758b966', 5),  -- carreira
       ('e4444444-d628-46ef-b838-b66d4758b966', 12), -- empregos
       ('e4444444-d628-46ef-b838-b66d4758b966', 23), -- networking
       ('e4444444-d628-46ef-b838-b66d4758b966', 28), -- tecnologia

-- Evento 5 (Workshop de Marketing)
       ('e5555555-d628-46ef-b838-b66d4758b966', 10), -- digital
       ('e5555555-d628-46ef-b838-b66d4758b966', 19), -- marketing
       ('e5555555-d628-46ef-b838-b66d4758b966', 22), -- negócios
       ('e5555555-d628-46ef-b838-b66d4758b966', 29), -- workshop

-- Evento 6 (Seminário de Saúde Mental)
       ('e6666666-d628-46ef-b838-b66d4758b966', 1),  -- apoio
       ('e6666666-d628-46ef-b838-b66d4758b966', 3),  -- bem-estar
       ('e6666666-d628-46ef-b838-b66d4758b966', 13), -- estudantes
       ('e6666666-d628-46ef-b838-b66d4758b966', 26), -- saúde mental

-- Evento 7 (Noite de Rock)
       ('e7777777-d628-46ef-b838-b66d4758b966', 2),  -- artes
       ('e7777777-d628-46ef-b838-b66d4758b966', 21), -- música
       ('e7777777-d628-46ef-b838-b66d4758b966', 24), -- performance
       ('e7777777-d628-46ef-b838-b66d4758b966', 25), -- rock

-- Evento 8 (Conferência sobre Blockchain)
       ('e8888888-d628-46ef-b838-b66d4758b966', 4),  -- blockchain
       ('e8888888-d628-46ef-b838-b66d4758b966', 8),  -- criptomoedas
       ('e8888888-d628-46ef-b838-b66d4758b966', 15), -- finanças
       ('e8888888-d628-46ef-b838-b66d4758b966', 28), -- tecnologia

-- Evento 9 (Introdução à Engenharia Elétrica)
       ('e9999999-d628-46ef-b838-b66d4758b966', 13), -- estudantes
       ('e9999999-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('e9999999-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('e9999999-d628-46ef-b838-b66d4758b966', 49), -- engenharia

-- Evento 10 (Hackathon de Inovação 2025)
       ('f1111111-d628-46ef-b838-b66d4758b966', 17), -- inovação
       ('f1111111-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('f1111111-d628-46ef-b838-b66d4758b966', 30), -- programação
       ('f1111111-d628-46ef-b838-b66d4758b966', 33), -- empreendedorismo

-- Evento 11 (Olimpíada de Matemática Aplicada)
       ('f2222222-d628-46ef-b838-b66d4758b966', 6),  -- ciência
       ('f2222222-d628-46ef-b838-b66d4758b966', 13), -- estudantes
       ('f2222222-d628-46ef-b838-b66d4758b966', 34), -- educação
       ('f2222222-d628-46ef-b838-b66d4758b966', 35), -- pesquisa

-- Evento 12 (Deep Learning na Prática)
       ('f3333333-d628-46ef-b838-b66d4758b966', 16), -- ia
       ('f3333333-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('f3333333-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('f3333333-d628-46ef-b838-b66d4758b966', 31), -- dados

-- Evento 13 (Smart Contracts e DeFi)
       ('f4444444-d628-46ef-b838-b66d4758b966', 4),  -- blockchain
       ('f4444444-d628-46ef-b838-b66d4758b966', 8),  -- criptomoedas
       ('f4444444-d628-46ef-b838-b66d4758b966', 15), -- finanças
       ('f4444444-d628-46ef-b838-b66d4758b966', 30), -- programação

-- Evento 14 (Exposição de Arte Digital Contemporânea)
       ('f5555555-d628-46ef-b838-b66d4758b966', 2),  -- artes
       ('f5555555-d628-46ef-b838-b66d4758b966', 9),  -- cultura
       ('f5555555-d628-46ef-b838-b66d4758b966', 10), -- digital
       ('f5555555-d628-46ef-b838-b66d4758b966', 32), -- design

-- Evento 15 (Economia Circular e Sustentabilidade)
       ('f6666666-d628-46ef-b838-b66d4758b966', 20), -- meio ambiente
       ('f6666666-d628-46ef-b838-b66d4758b966', 22), -- negócios
       ('f6666666-d628-46ef-b838-b66d4758b966', 27), -- sustentabilidade
       ('f6666666-d628-46ef-b838-b66d4758b966', 34), -- educação

-- Evento 16 (Física Quântica para Iniciantes)
       ('f7777777-d628-46ef-b838-b66d4758b966', 6),  -- ciência
       ('f7777777-d628-46ef-b838-b66d4758b966', 13), -- estudantes
       ('f7777777-d628-46ef-b838-b66d4758b966', 34), -- educação
       ('f7777777-d628-46ef-b838-b66d4758b966', 35), -- pesquisa

-- Evento 17 (Mindfulness e Produtividade)
       ('f8888888-d628-46ef-b838-b66d4758b966', 3),  -- bem-estar
       ('f8888888-d628-46ef-b838-b66d4758b966', 26), -- saúde mental
       ('f8888888-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('f8888888-d628-46ef-b838-b66d4758b966', 40), -- soft skills

-- Evento 18 (Química Orgânica Avançada)
       ('f9999999-d628-46ef-b838-b66d4758b966', 6),  -- ciência
       ('f9999999-d628-46ef-b838-b66d4758b966', 34), -- educação
       ('f9999999-d628-46ef-b838-b66d4758b966', 35), -- pesquisa
       ('f9999999-d628-46ef-b838-b66d4758b966', 49), -- engenharia

-- Evento 19 (Investindo em Criptomoedas com Segurança)
       ('11111111-d628-46ef-b838-b66d4758b966', 8),  -- criptomoedas
       ('11111111-d628-46ef-b838-b66d4758b966', 15), -- finanças
       ('11111111-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('11111111-d628-46ef-b838-b66d4758b966', 36), -- segurança

-- Evento 20 (Empreendedorismo e Gestão de Startups)
       ('12222222-d628-46ef-b838-b66d4758b966', 5),  -- carreira
       ('12222222-d628-46ef-b838-b66d4758b966', 22), -- negócios
       ('12222222-d628-46ef-b838-b66d4758b966', 33), -- empreendedorismo
       ('12222222-d628-46ef-b838-b66d4758b966', 43), -- startups

-- Evento 21 (Realidade Virtual na Educação)
       ('13333333-d628-46ef-b838-b66d4758b966', 17), -- inovação
       ('13333333-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('13333333-d628-46ef-b838-b66d4758b966', 34), -- educação
       ('13333333-d628-46ef-b838-b66d4758b966', 44), -- jogos

-- Evento 22 (Biotecnologia e Genética Molecular)
       ('14444444-d628-46ef-b838-b66d4758b966', 6),  -- ciência
       ('14444444-d628-46ef-b838-b66d4758b966', 17), -- inovação
       ('14444444-d628-46ef-b838-b66d4758b966', 35), -- pesquisa
       ('14444444-d628-46ef-b838-b66d4758b966', 49), -- engenharia

-- Evento 23 (Growth Hacking para Startups)
       ('15555555-d628-46ef-b838-b66d4758b966', 10), -- digital
       ('15555555-d628-46ef-b838-b66d4758b966', 19), -- marketing
       ('15555555-d628-46ef-b838-b66d4758b966', 33), -- empreendedorismo
       ('15555555-d628-46ef-b838-b66d4758b966', 43), -- startups

-- Evento 24 (BIM na Construção Civil)
       ('16666666-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('16666666-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('16666666-d628-46ef-b838-b66d4758b966', 49), -- engenharia
       ('16666666-d628-46ef-b838-b66d4758b966', 50), -- arquitetura

-- Evento 25 (Festival de Jazz Universitário)
       ('17777777-d628-46ef-b838-b66d4758b966', 2),  -- artes
       ('17777777-d628-46ef-b838-b66d4758b966', 9),  -- cultura
       ('17777777-d628-46ef-b838-b66d4758b966', 14), -- festival
       ('17777777-d628-46ef-b838-b66d4758b966', 21), -- música

-- Evento 26 (Robótica Colaborativa na Indústria 4.0)
       ('18888888-d628-46ef-b838-b66d4758b966', 17), -- inovação
       ('18888888-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('18888888-d628-46ef-b838-b66d4758b966', 49), -- engenharia
       ('18888888-d628-46ef-b838-b66d4758b966', 35), -- pesquisa

-- Evento 27 (Psicologia Positiva e Felicidade)
       ('19999999-d628-46ef-b838-b66d4758b966', 3),  -- bem-estar
       ('19999999-d628-46ef-b838-b66d4758b966', 26), -- saúde mental
       ('19999999-d628-46ef-b838-b66d4758b966', 34), -- educação
       ('19999999-d628-46ef-b838-b66d4758b966', 40), -- soft skills

-- Evento 28 (Desenvolvimento Full Stack com React e Node)
       ('21111111-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('21111111-d628-46ef-b838-b66d4758b966', 30), -- programação
       ('21111111-d628-46ef-b838-b66d4758b966', 39), -- web
       ('21111111-d628-46ef-b838-b66d4758b966', 29), -- workshop

-- Evento 29 (Finanças Pessoais para Jovens Profissionais)
       ('22222222-d628-46ef-b838-b66d4758b966', 5),  -- carreira
       ('22222222-d628-46ef-b838-b66d4758b966', 15), -- finanças
       ('22222222-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('22222222-d628-46ef-b838-b66d4758b966', 34), -- educação

-- Evento 30 (Big Data e Analytics com Python)
       ('23333333-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('23333333-d628-46ef-b838-b66d4758b966', 30), -- programação
       ('23333333-d628-46ef-b838-b66d4758b966', 31), -- dados
       ('23333333-d628-46ef-b838-b66d4758b966', 29), -- workshop

-- Evento 31 (Arquitetura Sustentável e Bioclimática)
       ('24444444-d628-46ef-b838-b66d4758b966', 20), -- meio ambiente
       ('24444444-d628-46ef-b838-b66d4758b966', 27), -- sustentabilidade
       ('24444444-d628-46ef-b838-b66d4758b966', 32), -- design
       ('24444444-d628-46ef-b838-b66d4758b966', 50), -- arquitetura

-- Evento 32 (Segurança Cibernética e Ethical Hacking)
       ('25555555-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('25555555-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('25555555-d628-46ef-b838-b66d4758b966', 30), -- programação
       ('25555555-d628-46ef-b838-b66d4758b966', 36), -- segurança

-- Evento 33 (Sarau Literário - Poesia Contemporânea)
       ('26666666-d628-46ef-b838-b66d4758b966', 2),  -- artes
       ('26666666-d628-46ef-b838-b66d4758b966', 9),  -- cultura
       ('26666666-d628-46ef-b838-b66d4758b966', 48), -- literatura
       ('26666666-d628-46ef-b838-b66d4758b966', 24), -- performance

-- Evento 34 (Flutter: Desenvolvimento Mobile Multiplataforma)
       ('27777777-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('27777777-d628-46ef-b838-b66d4758b966', 30), -- programação
       ('27777777-d628-46ef-b838-b66d4758b966', 38), -- mobile
       ('27777777-d628-46ef-b838-b66d4758b966', 29), -- workshop

-- Evento 35 (Direito Digital e LGPD)
       ('28888888-d628-46ef-b838-b66d4758b966', 10), -- digital
       ('28888888-d628-46ef-b838-b66d4758b966', 34), -- educação
       ('28888888-d628-46ef-b838-b66d4758b966', 36), -- segurança
       ('28888888-d628-46ef-b838-b66d4758b966', 51), -- jurídico

-- Evento 36 (Kubernetes e Orquestração de Containers)
       ('29999999-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('29999999-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('29999999-d628-46ef-b838-b66d4758b966', 37), -- cloud
       ('29999999-d628-46ef-b838-b66d4758b966', 30), -- programação

-- Evento 37 (Treinamento Funcional e Performance)
       ('31111111-d628-46ef-b838-b66d4758b966', 3),  -- bem-estar
       ('31111111-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('31111111-d628-46ef-b838-b66d4758b966', 45), -- esportes
       ('31111111-d628-46ef-b838-b66d4758b966', 24), -- performance

-- Evento 38 (Comunicação Não-Violenta no Trabalho)
       ('32222222-d628-46ef-b838-b66d4758b966', 34), -- educação
       ('32222222-d628-46ef-b838-b66d4758b966', 40), -- soft skills
       ('32222222-d628-46ef-b838-b66d4758b966', 41), -- liderança
       ('32222222-d628-46ef-b838-b66d4758b966', 5),  -- carreira

-- Evento 39 (Mostra de Curtas-Metragens Estudantis)
       ('33333333-d628-46ef-b838-b66d4758b966', 2),  -- artes
       ('33333333-d628-46ef-b838-b66d4758b966', 9),  -- cultura
       ('33333333-d628-46ef-b838-b66d4758b966', 13), -- estudantes
       ('33333333-d628-46ef-b838-b66d4758b966', 46), -- cinema

-- Evento 40 (Fotografia de Retrato e Iluminação)
       ('34444444-d628-46ef-b838-b66d4758b966', 2),  -- artes
       ('34444444-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('34444444-d628-46ef-b838-b66d4758b966', 32), -- design
       ('34444444-d628-46ef-b838-b66d4758b966', 47), -- fotografia

-- Evento 41 (Manutenção Preditiva com IoT)
       ('35555555-d628-46ef-b838-b66d4758b966', 17), -- inovação
       ('35555555-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('35555555-d628-46ef-b838-b66d4758b966', 31), -- dados
       ('35555555-d628-46ef-b838-b66d4758b966', 49), -- engenharia

-- Evento 42 (IoT e Casas Inteligentes)
       ('36666666-d628-46ef-b838-b66d4758b966', 10), -- digital
       ('36666666-d628-46ef-b838-b66d4758b966', 17), -- inovação
       ('36666666-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('36666666-d628-46ef-b838-b66d4758b966', 29), -- workshop

-- Evento 43 (Filosofia da Tecnologia)
       ('37777777-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('37777777-d628-46ef-b838-b66d4758b966', 34), -- educação
       ('37777777-d628-46ef-b838-b66d4758b966', 35), -- pesquisa
       ('37777777-d628-46ef-b838-b66d4758b966', 6),  -- ciência

-- Evento 44 (CI/CD com GitHub Actions)
       ('38888888-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('38888888-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('38888888-d628-46ef-b838-b66d4758b966', 30), -- programação
       ('38888888-d628-46ef-b838-b66d4758b966', 37), -- cloud

-- Evento 45 (Jornalismo de Dados e Visualização)
       ('39999999-d628-46ef-b838-b66d4758b966', 31), -- dados
       ('39999999-d628-46ef-b838-b66d4758b966', 32), -- design
       ('39999999-d628-46ef-b838-b66d4758b966', 34), -- educação
       ('39999999-d628-46ef-b838-b66d4758b966', 29), -- workshop

-- Evento 46 (Design Thinking e UX Research)
       ('41111111-d628-46ef-b838-b66d4758b966', 17), -- inovação
       ('41111111-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('41111111-d628-46ef-b838-b66d4758b966', 32), -- design
       ('41111111-d628-46ef-b838-b66d4758b966', 39), -- web

-- Evento 47 (Primeiros Socorros e Suporte Básico de Vida)
       ('42222222-d628-46ef-b838-b66d4758b966', 1),  -- apoio
       ('42222222-d628-46ef-b838-b66d4758b966', 3),  -- bem-estar
       ('42222222-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('42222222-d628-46ef-b838-b66d4758b966', 34), -- educação

-- Evento 48 (TensorFlow e Redes Neurais)
       ('43333333-d628-46ef-b838-b66d4758b966', 16), -- ia
       ('43333333-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('43333333-d628-46ef-b838-b66d4758b966', 30), -- programação
       ('43333333-d628-46ef-b838-b66d4758b966', 31), -- dados

-- Evento 49 (Turismo Sustentável e Ecoturismo)
       ('44444444-d628-46ef-b838-b66d4758b966', 20), -- meio ambiente
       ('44444444-d628-46ef-b838-b66d4758b966', 22), -- negócios
       ('44444444-d628-46ef-b838-b66d4758b966', 27), -- sustentabilidade
       ('44444444-d628-46ef-b838-b66d4758b966', 34), -- educação

-- Evento 50 (Game Jam 48h - Desenvolvimento de Jogos)
       ('45555555-d628-46ef-b838-b66d4758b966', 17), -- inovação
       ('45555555-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('45555555-d628-46ef-b838-b66d4758b966', 30), -- programação
       ('45555555-d628-46ef-b838-b66d4758b966', 44), -- jogos

-- Evento 51 (Nutrição Esportiva para Atletas)
       ('46666666-d628-46ef-b838-b66d4758b966', 3),  -- bem-estar
       ('46666666-d628-46ef-b838-b66d4758b966', 29), -- workshop
       ('46666666-d628-46ef-b838-b66d4758b966', 34), -- educação
       ('46666666-d628-46ef-b838-b66d4758b966', 45), -- esportes

-- Evento 52 (Apache Spark e Processamento Distribuído)
       ('47777777-d628-46ef-b838-b66d4758b966', 28), -- tecnologia
       ('47777777-d628-46ef-b838-b66d4758b966', 30), -- programação
       ('47777777-d628-46ef-b838-b66d4758b966', 31), -- dados
       ('47777777-d628-46ef-b838-b66d4758b966', 37), -- cloud

-- Evento 53 (Diplomacia e Negociação Internacional)
       ('48888888-d628-46ef-b838-b66d4758b966', 18), -- internacional
       ('48888888-d628-46ef-b838-b66d4758b966', 22), -- negócios
       ('48888888-d628-46ef-b838-b66d4758b966', 34), -- educação
       ('48888888-d628-46ef-b838-b66d4758b966', 40);
-- soft skills

-- Insert event speakers para os 50 eventos
INSERT INTO event_speakers (event_id, speaker_id)
VALUES
-- Evento 1: Inteligência Artificial e o Futuro do Trabalho
('e153c21a-d628-46ef-b838-b66d4758b966', 1),  -- Alan Turing
('e153c21a-d628-46ef-b838-b66d4758b966', 7),  -- Margaret Hamilton

-- Evento 2: Festival Cultural Internacional 2026
('e2222222-d628-46ef-b838-b66d4758b966', 19), -- Malala Yousafzai

-- Evento 3: Mudanças Climáticas: Ciência e Ação
('e3333333-d628-46ef-b838-b66d4758b966', 8),  -- Carl Sagan
('e3333333-d628-46ef-b838-b66d4758b966', 13), -- Jane Goodall
('e3333333-d628-46ef-b838-b66d4758b966', 25), -- Rachel Carson

-- Evento 4: Feira de Carreiras 2026: Tecnologia e Inovação
('e4444444-d628-46ef-b838-b66d4758b966', 14), -- Elon Musk
('e4444444-d628-46ef-b838-b66d4758b966', 15), -- Sheryl Sandberg

-- Evento 5: Workshop de Estratégias de Marketing Digital
('e5555555-d628-46ef-b838-b66d4758b966', 10), -- Steve Wozniak
('e5555555-d628-46ef-b838-b66d4758b966', 22), -- Mark Zuckerberg

-- Evento 6: Seminário de Saúde Mental e Bem-Estar
('e6666666-d628-46ef-b838-b66d4758b966', 32), -- Yuval Noah Harari

-- Evento 7: Noite de Rock na Universidade
('e7777777-d628-46ef-b838-b66d4758b966', 9),  -- Hedy Lamarr

-- Evento 8: Conferência sobre Blockchain e Criptomoedas
('e8888888-d628-46ef-b838-b66d4758b966', 9),  -- Hedy Lamarr
('e8888888-d628-46ef-b838-b66d4758b966', 4),  -- Nikola Tesla

-- Evento 9: Introdução à Engenharia Elétrica
('e9999999-d628-46ef-b838-b66d4758b966', 4),  -- Nikola Tesla

-- Evento 10: Hackathon de Inovação 2025
('f1111111-d628-46ef-b838-b66d4758b966', 10), -- Steve Wozniak
('f1111111-d628-46ef-b838-b66d4758b966', 18), -- Bill Gates

-- Evento 11: Olimpíada de Matemática Aplicada
('f2222222-d628-46ef-b838-b66d4758b966', 5),  -- Ada Lovelace
('f2222222-d628-46ef-b838-b66d4758b966', 21), -- Katherine Johnson

-- Evento 12: Deep Learning na Prática
('f3333333-d628-46ef-b838-b66d4758b966', 1),  -- Alan Turing
('f3333333-d628-46ef-b838-b66d4758b966', 7),  -- Margaret Hamilton

-- Evento 13: Smart Contracts e DeFi
('f4444444-d628-46ef-b838-b66d4758b966', 11), -- Tim Berners-Lee
('f4444444-d628-46ef-b838-b66d4758b966', 44), -- Jan Koum

-- Evento 14: Exposição de Arte Digital Contemporânea
('f5555555-d628-46ef-b838-b66d4758b966', 9),  -- Hedy Lamarr

-- Evento 15: Economia Circular e Sustentabilidade
('f6666666-d628-46ef-b838-b66d4758b966', 13), -- Jane Goodall
('f6666666-d628-46ef-b838-b66d4758b966', 25), -- Rachel Carson

-- Evento 16: Física Quântica para Iniciantes
('f7777777-d628-46ef-b838-b66d4758b966', 6),  -- Richard Feynman
('f7777777-d628-46ef-b838-b66d4758b966', 16), -- Stephen Hawking

-- Evento 17: Mindfulness e Produtividade
('f8888888-d628-46ef-b838-b66d4758b966', 32), -- Yuval Noah Harari

-- Evento 18: Química Orgânica Avançada
('f9999999-d628-46ef-b838-b66d4758b966', 2),  -- Marie Curie
('f9999999-d628-46ef-b838-b66d4758b966', 29), -- Rosalind Franklin

-- Evento 19: Investindo em Criptomoedas com Segurança
('11111111-d628-46ef-b838-b66d4758b966', 18), -- Bill Gates
('11111111-d628-46ef-b838-b66d4758b966', 26), -- Jeff Bezos

-- Evento 20: Empreendedorismo e Gestão de Startups
('12222222-d628-46ef-b838-b66d4758b966', 14), -- Elon Musk
('12222222-d628-46ef-b838-b66d4758b966', 15), -- Sheryl Sandberg
('12222222-d628-46ef-b838-b66d4758b966', 36), -- Reed Hastings

-- Evento 21: Realidade Virtual na Educação
('13333333-d628-46ef-b838-b66d4758b966', 22), -- Mark Zuckerberg

-- Evento 22: Biotecnologia e Genética Molecular
('14444444-d628-46ef-b838-b66d4758b966', 27), -- Barbara McClintock
('14444444-d628-46ef-b838-b66d4758b966', 39), -- Jennifer Doudna

-- Evento 23: Growth Hacking para Startups
('15555555-d628-46ef-b838-b66d4758b966', 22), -- Mark Zuckerberg
('15555555-d628-46ef-b838-b66d4758b966', 42), -- Brian Chesky

-- Evento 24: BIM na Construção Civil
('16666666-d628-46ef-b838-b66d4758b966', 24), -- Larry Page

-- Evento 25: Festival de Jazz Universitário
('17777777-d628-46ef-b838-b66d4758b966', 19), -- Malala Yousafzai

-- Evento 26: Robótica Colaborativa na Indústria 4.0
('18888888-d628-46ef-b838-b66d4758b966', 10), -- Steve Wozniak
('18888888-d628-46ef-b838-b66d4758b966', 4),  -- Nikola Tesla

-- Evento 27: Psicologia Positiva e Felicidade
('19999999-d628-46ef-b838-b66d4758b966', 32), -- Yuval Noah Harari

-- Evento 28: Desenvolvimento Full Stack com React e Node
('21111111-d628-46ef-b838-b66d4758b966', 11), -- Tim Berners-Lee
('21111111-d628-46ef-b838-b66d4758b966', 12), -- Linus Torvalds

-- Evento 29: Finanças Pessoais para Jovens Profissionais
('22222222-d628-46ef-b838-b66d4758b966', 18), -- Bill Gates
('22222222-d628-46ef-b838-b66d4758b966', 26), -- Jeff Bezos

-- Evento 30: Big Data e Analytics com Python
('23333333-d628-46ef-b838-b66d4758b966', 3),  -- Grace Hopper
('23333333-d628-46ef-b838-b66d4758b966', 21), -- Katherine Johnson

-- Evento 31: Arquitetura Sustentável e Bioclimática
('24444444-d628-46ef-b838-b66d4758b966', 13), -- Jane Goodall

-- Evento 32: Segurança Cibernética e Ethical Hacking
('25555555-d628-46ef-b838-b66d4758b966', 11), -- Tim Berners-Lee
('25555555-d628-46ef-b838-b66d4758b966', 12), -- Linus Torvalds

-- Evento 33: Sarau Literário - Poesia Contemporânea
('26666666-d628-46ef-b838-b66d4758b966', 19), -- Malala Yousafzai

-- Evento 34: Flutter: Desenvolvimento Mobile Multiplataforma
('27777777-d628-46ef-b838-b66d4758b966', 12), -- Linus Torvalds
('27777777-d628-46ef-b838-b66d4758b966', 40), -- Daniel Ek

-- Evento 35: Direito Digital e LGPD
('28888888-d628-46ef-b838-b66d4758b966', 11), -- Tim Berners-Lee

-- Evento 36: Kubernetes e Orquestração de Containers
('29999999-d628-46ef-b838-b66d4758b966', 12), -- Linus Torvalds
('29999999-d628-46ef-b838-b66d4758b966', 30), -- Sundar Pichai

-- Evento 37: Treinamento Funcional e Performance
('31111111-d628-46ef-b838-b66d4758b966', 17), -- Mae Jemison
('31111111-d628-46ef-b838-b66d4758b966', 31), -- Sally Ride

-- Evento 38: Comunicação Não-Violenta no Trabalho
('32222222-d628-46ef-b838-b66d4758b966', 15), -- Sheryl Sandberg
('32222222-d628-46ef-b838-b66d4758b966', 32), -- Yuval Noah Harari

-- Evento 39: Mostra de Curtas-Metragens Estudantis
('33333333-d628-46ef-b838-b66d4758b966', 19), -- Malala Yousafzai

-- Evento 40: Fotografia de Retrato e Iluminação
('34444444-d628-46ef-b838-b66d4758b966', 9),  -- Hedy Lamarr

-- Evento 41: Manutenção Preditiva com IoT
('35555555-d628-46ef-b838-b66d4758b966', 4),  -- Nikola Tesla
('35555555-d628-46ef-b838-b66d4758b966', 10), -- Steve Wozniak

-- Evento 42: IoT e Casas Inteligentes
('36666666-d628-46ef-b838-b66d4758b966', 10), -- Steve Wozniak
('36666666-d628-46ef-b838-b66d4758b966', 14), -- Elon Musk

-- Evento 43: Filosofia da Tecnologia
('37777777-d628-46ef-b838-b66d4758b966', 32), -- Yuval Noah Harari
('37777777-d628-46ef-b838-b66d4758b966', 16), -- Stephen Hawking

-- Evento 44: CI/CD com GitHub Actions
('38888888-d628-46ef-b838-b66d4758b966', 12), -- Linus Torvalds
('38888888-d628-46ef-b838-b66d4758b966', 28), -- Jack Dorsey

-- Evento 45: Jornalismo de Dados e Visualização
('39999999-d628-46ef-b838-b66d4758b966', 3),  -- Grace Hopper
('39999999-d628-46ef-b838-b66d4758b966', 21), -- Katherine Johnson

-- Evento 46: Design Thinking e UX Research
('41111111-d628-46ef-b838-b66d4758b966', 46), -- Kevin Systrom
('41111111-d628-46ef-b838-b66d4758b966', 42), -- Brian Chesky

-- Evento 47: Primeiros Socorros e Suporte Básico de Vida
('42222222-d628-46ef-b838-b66d4758b966', 17), -- Mae Jemison

-- Evento 48: TensorFlow e Redes Neurais
('43333333-d628-46ef-b838-b66d4758b966', 1),  -- Alan Turing
('43333333-d628-46ef-b838-b66d4758b966', 7),  -- Margaret Hamilton
('43333333-d628-46ef-b838-b66d4758b966', 30), -- Sundar Pichai

-- Evento 49: Turismo Sustentável e Ecoturismo
('44444444-d628-46ef-b838-b66d4758b966', 13), -- Jane Goodall
('44444444-d628-46ef-b838-b66d4758b966', 25), -- Rachel Carson

-- Evento 50: Game Jam 48h - Desenvolvimento de Jogos
('45555555-d628-46ef-b838-b66d4758b966', 22), -- Mark Zuckerberg
('45555555-d628-46ef-b838-b66d4758b966', 46), -- Kevin Systrom

-- Evento 51: Nutrição Esportiva para Atletas
('46666666-d628-46ef-b838-b66d4758b966', 17), -- Mae Jemison
('46666666-d628-46ef-b838-b66d4758b966', 31), -- Sally Ride

-- Evento 52: Apache Spark e Processamento Distribuído
('47777777-d628-46ef-b838-b66d4758b966', 12), -- Linus Torvalds
('47777777-d628-46ef-b838-b66d4758b966', 24), -- Larry Page

-- Evento 53: Diplomacia e Negociação Internacional
('48888888-d628-46ef-b838-b66d4758b966', 19), -- Malala Yousafzai
('48888888-d628-46ef-b838-b66d4758b966', 32);
-- Yuval Noah Harari

-- Insert event requirements para os 50 eventos (quantidade variada)
INSERT INTO public.event_requirements (event_id, requirement_id)
VALUES
-- Evento 1 (Inteligência Artificial) - 4 requisitos
('e153c21a-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('e153c21a-d628-46ef-b838-b66d4758b966', 5),  -- Conhecimento básico de marketing é útil
('e153c21a-d628-46ef-b838-b66d4758b966', 6),  -- Entrada gratuita
('e153c21a-d628-46ef-b838-b66d4758b966', 9),  -- Recomendado entendimento básico de criptomoedas

-- Evento 2 (Festival Cultural) - 4 requisitos
('e2222222-d628-46ef-b838-b66d4758b966', 3),  -- Aberto a todos os alunos e corpo docente
('e2222222-d628-46ef-b838-b66d4758b966', 4),  -- Aberto a todos os estudantes
('e2222222-d628-46ef-b838-b66d4758b966', 8),  -- Inscrição necessária para vales-alimentação
('e2222222-d628-46ef-b838-b66d4758b966', 9),  -- Recomendado entendimento básico de criptomoedas

-- Evento 3 (Mudanças Climáticas) - 3 requisitos
('e3333333-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('e3333333-d628-46ef-b838-b66d4758b966', 2),  -- $5 para corpo docente/funcionários
('e3333333-d628-46ef-b838-b66d4758b966', 3),  -- Aberto a todos os alunos e corpo docente

-- Evento 4 (Feira de Carreiras) - 3 requisitos
('e4444444-d628-46ef-b838-b66d4758b966', 4),  -- Aberto a todos os estudantes
('e4444444-d628-46ef-b838-b66d4758b966', 12), -- Trazer currículos impressos
('e4444444-d628-46ef-b838-b66d4758b966', 6),  -- Entrada gratuita

-- Evento 5 (Workshop de Marketing) - 3 requisitos
('e5555555-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('e5555555-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória
('e5555555-d628-46ef-b838-b66d4758b966', 14), -- Material de anotação

-- Evento 6 (Seminário de Saúde Mental) - 2 requisitos
('e6666666-d628-46ef-b838-b66d4758b966', 4),  -- Aberto a todos os estudantes
('e6666666-d628-46ef-b838-b66d4758b966', 6),  -- Entrada gratuita

-- Evento 7 (Noite de Rock) - 2 requisitos
('e7777777-d628-46ef-b838-b66d4758b966', 2),  -- $5 para corpo docente/funcionários
('e7777777-d628-46ef-b838-b66d4758b966', 7),  -- Estudantes: grátis

-- Evento 8 (Conferência sobre Blockchain) - 5 requisitos
('e8888888-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('e8888888-d628-46ef-b838-b66d4758b966', 9),  -- Recomendado entendimento básico de criptomoedas
('e8888888-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória
('e8888888-d628-46ef-b838-b66d4758b966', 15), -- Certificado de conclusão será emitido
('e8888888-d628-46ef-b838-b66d4758b966', 30), -- Coffee break incluso

-- Evento 9 (Introdução à Engenharia Elétrica) - 3 requisitos
('e9999999-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('e9999999-d628-46ef-b838-b66d4758b966', 14), -- Material de anotação
('e9999999-d628-46ef-b838-b66d4758b966', 31), -- Material didático será fornecido

-- Evento 10 (Hackathon de Inovação 2025) - 4 requisitos
('f1111111-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('f1111111-d628-46ef-b838-b66d4758b966', 22), -- Necessário ter conta no GitHub
('f1111111-d628-46ef-b838-b66d4758b966', 40), -- Necessário laptop com mínimo 8GB RAM
('f1111111-d628-46ef-b838-b66d4758b966', 30), -- Coffee break incluso

-- Evento 11 (Olimpíada de Matemática Aplicada) - 2 requisitos
('f2222222-d628-46ef-b838-b66d4758b966', 34), -- Aberto apenas para alunos matriculados
('f2222222-d628-46ef-b838-b66d4758b966', 18), -- Trazer documentos de identificação

-- Evento 12 (Deep Learning na Prática) - 5 requisitos
('f3333333-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('f3333333-d628-46ef-b838-b66d4758b966', 13), -- Conhecimento prévio em Python recomendado
('f3333333-d628-46ef-b838-b66d4758b966', 40), -- Necessário laptop com mínimo 8GB RAM
('f3333333-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória
('f3333333-d628-46ef-b838-b66d4758b966', 26), -- Certificado digital disponível após avaliação

-- Evento 13 (Smart Contracts e DeFi) - 4 requisitos
('f4444444-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('f4444444-d628-46ef-b838-b66d4758b966', 22), -- Necessário ter conta no GitHub
('f4444444-d628-46ef-b838-b66d4758b966', 39), -- Conhecimento em Git e controle de versão
('f4444444-d628-46ef-b838-b66d4758b966', 9),  -- Recomendado entendimento básico de criptomoedas

-- Evento 14 (Exposição de Arte Digital Contemporânea) - 1 requisito
('f5555555-d628-46ef-b838-b66d4758b966', 6),  -- Entrada gratuita

-- Evento 15 (Economia Circular e Sustentabilidade) - 2 requisitos
('f6666666-d628-46ef-b838-b66d4758b966', 3),  -- Aberto a todos os alunos e corpo docente
('f6666666-d628-46ef-b838-b66d4758b966', 14), -- Material de anotação

-- Evento 16 (Física Quântica para Iniciantes) - 3 requisitos
('f7777777-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('f7777777-d628-46ef-b838-b66d4758b966', 14), -- Material de anotação
('f7777777-d628-46ef-b838-b66d4758b966', 33), -- Conhecimento básico de estatística recomendado

-- Evento 17 (Mindfulness e Produtividade) - 2 requisitos
('f8888888-d628-46ef-b838-b66d4758b966', 4),  -- Aberto a todos os estudantes
('f8888888-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória

-- Evento 18 (Química Orgânica Avançada) - 3 requisitos
('f9999999-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('f9999999-d628-46ef-b838-b66d4758b966', 14), -- Material de anotação
('f9999999-d628-46ef-b838-b66d4758b966', 31), -- Material didático será fornecido

-- Evento 19 (Investindo em Criptomoedas com Segurança) - 4 requisitos
('11111111-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('11111111-d628-46ef-b838-b66d4758b966', 9),  -- Recomendado entendimento básico de criptomoedas
('11111111-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória
('11111111-d628-46ef-b838-b66d4758b966', 21), -- Taxa de R$ 10,00 para não estudantes

-- Evento 20 (Empreendedorismo e Gestão de Startups) - 3 requisitos
('12222222-d628-46ef-b838-b66d4758b966', 4),  -- Aberto a todos os estudantes
('12222222-d628-46ef-b838-b66d4758b966', 28), -- Recomendado para estudantes de Administração e Economia
('12222222-d628-46ef-b838-b66d4758b966', 37), -- Trazer portfolio digital ou impresso

-- Evento 21 (Realidade Virtual na Educação) - 2 requisitos
('13333333-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória
('13333333-d628-46ef-b838-b66d4758b966', 25), -- Trazer dispositivo móvel

-- Evento 22 (Biotecnologia e Genética Molecular) - 3 requisitos
('14444444-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('14444444-d628-46ef-b838-b66d4758b966', 17), -- Recomendado para estudantes de Engenharia
('14444444-d628-46ef-b838-b66d4758b966', 35), -- Necessário experiência prévia com SQL

-- Evento 23 (Growth Hacking para Startups) - 4 requisitos
('15555555-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('15555555-d628-46ef-b838-b66d4758b966', 5),  -- Conhecimento básico de marketing é útil
('15555555-d628-46ef-b838-b66d4758b966', 28), -- Recomendado para estudantes de Administração e Economia
('15555555-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória

-- Evento 24 (BIM na Construção Civil) - 4 requisitos
('16666666-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('16666666-d628-46ef-b838-b66d4758b966', 40), -- Necessário laptop com mínimo 8GB RAM
('16666666-d628-46ef-b838-b66d4758b966', 17), -- Recomendado para estudantes de Engenharia
('16666666-d628-46ef-b838-b66d4758b966', 31), -- Material didático será fornecido

-- Evento 25 (Festival de Jazz Universitário) - 2 requisitos
('17777777-d628-46ef-b838-b66d4758b966', 7),  -- Estudantes: grátis
('17777777-d628-46ef-b838-b66d4758b966', 2),  -- $5 para corpo docente/funcionários

-- Evento 26 (Robótica Colaborativa na Indústria 4.0) - 3 requisitos
('18888888-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('18888888-d628-46ef-b838-b66d4758b966', 17), -- Recomendado para estudantes de Engenharia
('18888888-d628-46ef-b838-b66d4758b966', 31), -- Material didático será fornecido

-- Evento 27 (Psicologia Positiva e Felicidade) - 2 requisitos
('19999999-d628-46ef-b838-b66d4758b966', 4),  -- Aberto a todos os estudantes
('19999999-d628-46ef-b838-b66d4758b966', 6),  -- Entrada gratuita

-- Evento 28 (Desenvolvimento Full Stack com React e Node) - 6 requisitos
('21111111-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('21111111-d628-46ef-b838-b66d4758b966', 13), -- Conhecimento prévio em Python recomendado
('21111111-d628-46ef-b838-b66d4758b966', 22), -- Necessário ter conta no GitHub
('21111111-d628-46ef-b838-b66d4758b966', 39), -- Conhecimento em Git e controle de versão
('21111111-d628-46ef-b838-b66d4758b966', 40), -- Necessário laptop com mínimo 8GB RAM
('21111111-d628-46ef-b838-b66d4758b966', 27), -- Inscrição limitada a 50 participantes

-- Evento 29 (Finanças Pessoais para Jovens Profissionais) - 2 requisitos
('22222222-d628-46ef-b838-b66d4758b966', 4),  -- Aberto a todos os estudantes
('22222222-d628-46ef-b838-b66d4758b966', 14), -- Material de anotação

-- Evento 30 (Big Data e Analytics com Python) - 5 requisitos
('23333333-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('23333333-d628-46ef-b838-b66d4758b966', 13), -- Conhecimento prévio em Python recomendado
('23333333-d628-46ef-b838-b66d4758b966', 33), -- Conhecimento básico de estatística recomendado
('23333333-d628-46ef-b838-b66d4758b966', 40), -- Necessário laptop com mínimo 8GB RAM
('23333333-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória

-- Evento 31 (Arquitetura Sustentável e Bioclimática) - 2 requisitos
('24444444-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('24444444-d628-46ef-b838-b66d4758b966', 14), -- Material de anotação

-- Evento 32 (Segurança Cibernética e Ethical Hacking) - 5 requisitos
('25555555-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('25555555-d628-46ef-b838-b66d4758b966', 13), -- Conhecimento prévio em Python recomendado
('25555555-d628-46ef-b838-b66d4758b966', 40), -- Necessário laptop com mínimo 8GB RAM
('25555555-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória
('25555555-d628-46ef-b838-b66d4758b966', 45), -- Recomendado para profissionais da área de TI

-- Evento 33 (Sarau Literário - Poesia Contemporânea) - 1 requisito
('26666666-d628-46ef-b838-b66d4758b966', 6),  -- Entrada gratuita

-- Evento 34 (Flutter: Desenvolvimento Mobile Multiplataforma) - 4 requisitos
('27777777-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('27777777-d628-46ef-b838-b66d4758b966', 13), -- Conhecimento prévio em Python recomendado
('27777777-d628-46ef-b838-b66d4758b966', 22), -- Necessário ter conta no GitHub
('27777777-d628-46ef-b838-b66d4758b966', 40), -- Necessário laptop com mínimo 8GB RAM

-- Evento 35 (Direito Digital e LGPD) - 3 requisitos
('28888888-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('28888888-d628-46ef-b838-b66d4758b966', 14), -- Material de anotação
('28888888-d628-46ef-b838-b66d4758b966', 28), -- Recomendado para estudantes de Administração e Economia

-- Evento 36 (Kubernetes e Orquestração de Containers) - 5 requisitos
('29999999-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('29999999-d628-46ef-b838-b66d4758b966', 40), -- Necessário laptop com mínimo 8GB RAM
('29999999-d628-46ef-b838-b66d4758b966', 44), -- Necessário conhecimento em Docker
('29999999-d628-46ef-b838-b66d4758b966', 45), -- Recomendado para profissionais da área de TI
('29999999-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória

-- Evento 37 (Treinamento Funcional e Performance) - 2 requisitos
('31111111-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória
('31111111-d628-46ef-b838-b66d4758b966', 38), -- Vestimenta casual permitida

-- Evento 38 (Comunicação Não-Violenta no Trabalho) - 2 requisitos
('32222222-d628-46ef-b838-b66d4758b966', 4),  -- Aberto a todos os estudantes
('32222222-d628-46ef-b838-b66d4758b966', 14), -- Material de anotação

-- Evento 39 (Mostra de Curtas-Metragens Estudantis) - 1 requisito
('33333333-d628-46ef-b838-b66d4758b966', 6),  -- Entrada gratuita

-- Evento 40 (Fotografia de Retrato e Iluminação) - 3 requisitos
('34444444-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória
('34444444-d628-46ef-b838-b66d4758b966', 25), -- Trazer dispositivo móvel
('34444444-d628-46ef-b838-b66d4758b966', 31), -- Material didático será fornecido

-- Evento 41 (Manutenção Preditiva com IoT) - 4 requisitos
('35555555-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('35555555-d628-46ef-b838-b66d4758b966', 13), -- Conhecimento prévio em Python recomendado
('35555555-d628-46ef-b838-b66d4758b966', 17), -- Recomendado para estudantes de Engenharia
('35555555-d628-46ef-b838-b66d4758b966', 31), -- Material didático será fornecido

-- Evento 42 (IoT e Casas Inteligentes) - 3 requisitos
('36666666-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('36666666-d628-46ef-b838-b66d4758b966', 25), -- Trazer dispositivo móvel
('36666666-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória

-- Evento 43 (Filosofia da Tecnologia) - 2 requisitos
('37777777-d628-46ef-b838-b66d4758b966', 4),  -- Aberto a todos os estudantes
('37777777-d628-46ef-b838-b66d4758b966', 14), -- Material de anotação

-- Evento 44 (CI/CD com GitHub Actions) - 4 requisitos
('38888888-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('38888888-d628-46ef-b838-b66d4758b966', 22), -- Necessário ter conta no GitHub
('38888888-d628-46ef-b838-b66d4758b966', 39), -- Conhecimento em Git e controle de versão
('38888888-d628-46ef-b838-b66d4758b966', 40), -- Necessário laptop com mínimo 8GB RAM

-- Evento 45 (Jornalismo de Dados e Visualização) - 4 requisitos
('39999999-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('39999999-d628-46ef-b838-b66d4758b966', 13), -- Conhecimento prévio em Python recomendado
('39999999-d628-46ef-b838-b66d4758b966', 33), -- Conhecimento básico de estatística recomendado
('39999999-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória

-- Evento 46 (Design Thinking e UX Research) - 3 requisitos
('41111111-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('41111111-d628-46ef-b838-b66d4758b966', 36), -- Recomendado para estudantes de Design e Comunicação
('41111111-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória

-- Evento 47 (Primeiros Socorros e Suporte Básico de Vida) - 3 requisitos
('42222222-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória
('42222222-d628-46ef-b838-b66d4758b966', 29), -- Necessário cadastro prévio no sistema
('42222222-d628-46ef-b838-b66d4758b966', 43), -- Certificado válido para horas complementares

-- Evento 48 (TensorFlow e Redes Neurais) - 6 requisitos
('43333333-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('43333333-d628-46ef-b838-b66d4758b966', 13), -- Conhecimento prévio em Python recomendado
('43333333-d628-46ef-b838-b66d4758b966', 24), -- Conhecimento intermediário em Java
('43333333-d628-46ef-b838-b66d4758b966', 40), -- Necessário laptop com mínimo 8GB RAM
('43333333-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória
('43333333-d628-46ef-b838-b66d4758b966', 50), -- Recomendado para estudantes de Ciências da Computação

-- Evento 49 (Turismo Sustentável e Ecoturismo) - 2 requisitos
('44444444-d628-46ef-b838-b66d4758b966', 4),  -- Aberto a todos os estudantes
('44444444-d628-46ef-b838-b66d4758b966', 6),  -- Entrada gratuita

-- Evento 50 (Game Jam 48h - Desenvolvimento de Jogos) - 5 requisitos
('45555555-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('45555555-d628-46ef-b838-b66d4758b966', 22), -- Necessário ter conta no GitHub
('45555555-d628-46ef-b838-b66d4758b966', 40), -- Necessário laptop com mínimo 8GB RAM
('45555555-d628-46ef-b838-b66d4758b966', 30), -- Coffee break incluso
('45555555-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória

-- Evento 51 (Nutrição Esportiva para Atletas) - 2 requisitos
('46666666-d628-46ef-b838-b66d4758b966', 14), -- Material de anotação
('46666666-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória

-- Evento 52 (Apache Spark e Processamento Distribuído) - 5 requisitos
('47777777-d628-46ef-b838-b66d4758b966', 1),  -- Trazer notebook
('47777777-d628-46ef-b838-b66d4758b966', 13), -- Conhecimento prévio em Python recomendado
('47777777-d628-46ef-b838-b66d4758b966', 40), -- Necessário laptop com mínimo 8GB RAM
('47777777-d628-46ef-b838-b66d4758b966', 45), -- Recomendado para profissionais da área de TI
('47777777-d628-46ef-b838-b66d4758b966', 16), -- Vagas limitadas - inscrição obrigatória

-- Evento 53 (Diplomacia e Negociação Internacional) - 3 requisitos
('48888888-d628-46ef-b838-b66d4758b966', 4),  -- Aberto a todos os estudantes
('48888888-d628-46ef-b838-b66d4758b966', 19), -- Conhecimento básico de inglês é desejável
('48888888-d628-46ef-b838-b66d4758b966', 14);
-- Material de anotação

-- EVENTO 1 (e9999999...) - 18 Inscritos, 15 Presentes
INSERT INTO registrations (user_id, event_id, attended, notified, registration_date)
VALUES ('11111111-1111-1111-1111-111111111111', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 10:00:00'),
       ('22222222-2222-2222-2222-222222222222', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 10:05:00'),
       ('33333333-3333-3333-3333-333333333333', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 10:10:00'),
       ('44444444-4444-4444-4444-444444444444', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 10:15:00'),
       ('55555555-5555-5555-5555-555555555555', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 10:20:00'),
       ('66666666-6666-6666-6666-666666666666', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 10:25:00'),
       ('77777777-7777-7777-7777-777777777777', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 10:30:00'),
       ('88888888-8888-8888-8888-888888888888', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 10:35:00'),
       ('99999999-9999-9999-9999-999999999999', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 10:40:00'),
       ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 10:45:00'),
       ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 10:50:00'),
       ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 10:55:00'),
       ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 11:00:00'),
       ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 11:05:00'),
       ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'e9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-01 11:10:00'),
       ('10101010-1010-1010-1010-101010101010', 'e9999999-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-04-01 11:15:00'),
       ('20202020-2020-2020-2020-202020202020', 'e9999999-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-04-01 11:20:00'),
       ('30303030-3030-3030-3030-303030303030', 'e9999999-d628-46ef-b838-b66d4758b966', FALSE, FALSE,
        '2024-04-01 11:25:00');

-- EVENTO 2 (f1111111...) - 15 Inscritos, 12 Presentes
INSERT INTO registrations (user_id, event_id, attended, notified, registration_date)
VALUES ('40404040-4040-4040-4040-404040404040', 'f1111111-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-02 09:00:00'),
       ('50505050-5050-5050-5050-505050505050', 'f1111111-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-02 09:10:00'),
       ('60606060-6060-6060-6060-606060606060', 'f1111111-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-02 09:20:00'),
       ('70707070-7070-7070-7070-707070707070', 'f1111111-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-02 09:30:00'),
       ('80808080-8080-8080-8080-808080808080', 'f1111111-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-02 09:40:00'),
       ('90909090-9090-9090-9090-909090909090', 'f1111111-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-02 09:50:00'),
       ('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', 'f1111111-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-02 10:00:00'),
       ('b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2', 'f1111111-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-02 10:10:00'),
       ('c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3', 'f1111111-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-02 10:20:00'),
       ('d4d4d4d4-d4d4-d4d4-d4d4-d4d4d4d4d4d4', 'f1111111-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-02 10:30:00'),
       ('e5e5e5e5-e5e5-e5e5-e5e5-e5e5e5e5e5e5', 'f1111111-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-02 10:40:00'),
       ('f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6', 'f1111111-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-02 10:50:00'),
       ('a0a0a0a0-a0a0-a0a0-a0a0-a0a0a0a0a0a0', 'f1111111-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-04-02 11:00:00'),
       ('b0b0b0b0-b0b0-b0b0-b0b0-b0b0b0b0b0b0', 'f1111111-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-04-02 11:10:00'),
       ('c0c0c0c0-c0c0-c0c0-c0c0-c0c0c0c0c0c0', 'f1111111-d628-46ef-b838-b66d4758b966', FALSE, FALSE,
        '2024-04-02 11:20:00');

-- EVENTO 3 (f6666666...) - 13 Presentes
INSERT INTO registrations (user_id, event_id, attended, notified, registration_date)
VALUES ('d0d0d0d0-d0d0-d0d0-d0d0-d0d0d0d0d0d0', 'f6666666-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-03 14:00:00'),
       ('e0e0e0e0-e0e0-e0e0-e0e0-e0e0e0e0e0e0', 'f6666666-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-03 14:05:00'),
       ('f0f0f0f0-f0f0-f0f0-f0f0-f0f0f0f0f0f0', 'f6666666-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-03 14:10:00'),
       ('a1b1c1d1-a1b1-c1d1-a1b1-c1d1a1b1c1d1', 'f6666666-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-04-03 14:15:00'),
       ('a2b2c2d2-a2b2-c2d2-a2b2-c2d2a2b2c2d2', 'f6666666-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-04-03 14:20:00'),
       ('a3b3c3d3-a3b3-c3d3-a3b3-c3d3a3b3c3d3', 'f6666666-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-03 14:25:00'),
       ('a4b4c4d4-a4b4-c4d4-a4b4-c4d4a4b4c4d4', 'f6666666-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-04-03 14:30:00'),
       ('a5b5c5d5-a5b5-c5d5-a5b5-c5d5a5b5c5d5', 'f6666666-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-03 14:35:00'),
       ('a6b6c6d6-a6b6-c6d6-a6b6-c6d6a6b6c6d6', 'f6666666-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-04-03 14:40:00'),
       ('a7b7c7d7-a7b7-c7d7-a7b7-c7d7a7b7c7d7', 'f6666666-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-03 14:45:00'),
       ('a8b8c8d8-a8b8-c8d8-a8b8-c8d8a8b8c8d8', 'f6666666-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-04-03 14:50:00'),
       ('a9b9c9d9-a9b9-c9d9-a9b9-c9d9a9b9c9d9', 'f6666666-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-03 14:55:00'),
       ('ad111111-1111-1111-1111-111111111111', 'f6666666-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-04-03 15:00:00'),
       ('ad222222-2222-2222-2222-222222222222', 'f6666666-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-04-03 15:05:00');
-- EVENTO 4 (f9999999...) - 16 Inscritos, 14 Presentes
INSERT INTO registrations (user_id, event_id, attended, notified, registration_date)
VALUES ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'f9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-01 09:00:00'),
       ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'f9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-01 09:10:00'),
       ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'f9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-01 09:20:00'),
       ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'f9999999-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-06-01 09:30:00'),
       ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'f9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-01 09:40:00'),
       ('10101010-1010-1010-1010-101010101010', 'f9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-01 09:50:00'),
       ('20202020-2020-2020-2020-202020202020', 'f9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-01 10:00:00'),
       ('30303030-3030-3030-3030-303030303030', 'f9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-01 10:10:00'),
       ('40404040-4040-4040-4040-404040404040', 'f9999999-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-06-01 10:20:00'),
       ('50505050-5050-5050-5050-505050505050', 'f9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-01 10:30:00'),
       ('60606060-6060-6060-6060-606060606060', 'f9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-01 10:40:00'),
       ('70707070-7070-7070-7070-707070707070', 'f9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-01 10:50:00'),
       ('80808080-8080-8080-8080-808080808080', 'f9999999-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-01 11:00:00'),
       ('90909090-9090-9090-9090-909090909090', 'f9999999-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-06-01 11:10:00'),
       ('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', 'f9999999-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-06-01 11:20:00'),
       ('b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2', 'f9999999-d628-46ef-b838-b66d4758b966', FALSE, FALSE,
        '2024-06-01 11:30:00');

-- EVENTO 5 (14444444...) - 12 Presentes
INSERT INTO registrations (user_id, event_id, attended, notified, registration_date)
VALUES ('c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3', '14444444-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-06-05 14:00:00'),
       ('d4d4d4d4-d4d4-d4d4-d4d4-d4d4d4d4d4d4', '14444444-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-06-05 14:10:00'),
       ('e5e5e5e5-e5e5-e5e5-e5e5-e5e5e5e5e5e5', '14444444-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-06-05 14:20:00'),
       ('f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6', '14444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-05 14:30:00'),
       ('a0a0a0a0-a0a0-a0a0-a0a0-a0a0a0a0a0a0', '14444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-05 14:40:00'),
       ('b0b0b0b0-b0b0-b0b0-b0b0-b0b0b0b0b0b0', '14444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-05 14:50:00'),
       ('c0c0c0c0-c0c0-c0c0-c0c0-c0c0c0c0c0c0', '14444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-05 15:00:00'),
       ('d0d0d0d0-d0d0-d0d0-d0d0-d0d0d0d0d0d0', '14444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-05 15:10:00'),
       ('e0e0e0e0-e0e0-e0e0-e0e0-e0e0e0e0e0e0', '14444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-05 15:20:00'),
       ('f0f0f0f0-f0f0-f0f0-f0f0-f0f0f0f0f0f0', '14444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-05 15:30:00'),
       ('a1b1c1d1-a1b1-c1d1-a1b1-c1d1a1b1c1d1', '14444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-05 15:40:00'),
       ('a2b2c2d2-a2b2-c2d2-a2b2-c2d2a2b2c2d2', '14444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-05 15:50:00');

-- EVENTO 6 (18888888...) - 14 Presentes
INSERT INTO registrations (user_id, event_id, attended, notified, registration_date)
VALUES ('a3b3c3d3-a3b3-c3d3-a3b3-c3d3a3b3c3d3', '18888888-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-06-10 08:00:00'),
       ('a4b4c4d4-a4b4-c4d4-a4b4-c4d4a4b4c4d4', '18888888-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-06-10 08:10:00'),
       ('a5b5c5d5-a5b5-c5d5-a5b5-c5d5a5b5c5d5', '18888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-10 08:20:00'),
       ('a6b6c6d6-a6b6-c6d6-a6b6-c6d6a6b6c6d6', '18888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-10 08:30:00'),
       ('a7b7c7d7-a7b7-c7d7-a7b7-c7d7a7b7c7d7', '18888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-10 08:40:00'),
       ('a8b8c8d8-a8b8-c8d8-a8b8-c8d8a8b8c8d8', '18888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-10 08:50:00'),
       ('a9b9c9d9-a9b9-c9d9-a9b9-c9d9a9b9c9d9', '18888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-10 09:00:00'),
       ('ad111111-1111-1111-1111-111111111111', '18888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-10 09:10:00'),
       ('ad222222-2222-2222-2222-222222222222', '18888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-10 09:20:00'),
       ('ad333333-3333-3333-3333-333333333333', '18888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-10 09:30:00'),
       ('ad444444-4444-4444-4444-444444444444', '18888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-10 09:40:00'),
       ('ad555555-5555-5555-5555-555555555555', '18888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-10 09:50:00'),
       ('f7d2e9b8-31a4-4c5d-92e1-8b0f7a63c294', '18888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-10 10:00:00'),
       ('be89dede-00f2-48eb-880b-c9b728ce5bfc', '18888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-10 10:10:00');

-- EVENTO 7 (23333333...) - 15 Presentes
INSERT INTO registrations (user_id, event_id, attended, notified, registration_date)
VALUES ('b82120cf-41a7-406a-b52d-259cdbef3041', '23333333-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-06-15 11:00:00'),
       ('5c0a92a1-b445-4e4b-807c-6fbca67b9092', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 11:15:00'),
       ('9be3d05c-7638-4f78-814a-ce4c21463262', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 11:30:00'),
       ('286c2d18-9814-4d88-a55d-14bacaefcf49', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 11:45:00'),
       ('073b9076-2317-4511-a9c3-535654e75363', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 12:00:00'),
       ('be4999bf-6d31-4414-a0a6-ae61d53a6387', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 12:15:00'),
       ('54307ac7-8117-42c3-abc2-a74b112979c3', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 12:30:00'),
       ('e6137fdc-6fc2-4776-8616-9e238c1b48a7', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 12:45:00'),
       ('11111111-1111-1111-1111-111111111111', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 13:00:00'),
       ('22222222-2222-2222-2222-222222222222', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 13:15:00'),
       ('33333333-3333-3333-3333-333333333333', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 13:30:00'),
       ('44444444-4444-4444-4444-444444444444', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 13:45:00'),
       ('55555555-5555-5555-5555-555555555555', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 14:00:00'),
       ('66666666-6666-6666-6666-666666666666', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 14:15:00'),
       ('77777777-7777-7777-7777-777777777777', '23333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-06-15 14:30:00');

-- EVENTO 8 (27777777...) - 12 Presentes
INSERT INTO registrations (user_id, event_id, attended, notified, registration_date)
VALUES ('88888888-8888-8888-8888-888888888888', '27777777-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-07-01 10:00:00'),
       ('99999999-9999-9999-9999-999999999999', '27777777-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-07-01 10:10:00'),
       ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '27777777-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-07-01 10:20:00'),
       ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '27777777-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-07-01 10:30:00'),
       ('cccccccc-cccc-cccc-cccc-cccccccccccc', '27777777-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-07-01 10:40:00'),
       ('dddddddd-dddd-dddd-dddd-dddddddddddd', '27777777-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-07-01 10:50:00'),
       ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '27777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-01 11:00:00'),
       ('ffffffff-ffff-ffff-ffff-ffffffffffff', '27777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-01 11:10:00'),
       ('10101010-1010-1010-1010-101010101010', '27777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-01 11:20:00'),
       ('20202020-2020-2020-2020-202020202020', '27777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-01 11:30:00'),
       ('30303030-3030-3030-3030-303030303030', '27777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-01 11:40:00'),
       ('40404040-4040-4040-4040-404040404040', '27777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-01 11:50:00');

-- EVENTO 9 (34444444...) - 13 Presentes
INSERT INTO registrations (user_id, event_id, attended, notified, registration_date)
VALUES ('50505050-5050-5050-5050-505050505050', '34444444-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-07-05 15:00:00'),
       ('60606060-6060-6060-6060-606060606060', '34444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-05 15:15:00'),
       ('70707070-7070-7070-7070-707070707070', '34444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-05 15:30:00'),
       ('80808080-8080-8080-8080-808080808080', '34444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-05 15:45:00'),
       ('90909090-9090-9090-9090-909090909090', '34444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-05 16:00:00'),
       ('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', '34444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-05 16:15:00'),
       ('b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2', '34444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-05 16:30:00'),
       ('c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3', '34444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-05 16:45:00'),
       ('d4d4d4d4-d4d4-d4d4-d4d4-d4d4d4d4d4d4', '34444444-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-07-05 17:00:00'),
       ('e5e5e5e5-e5e5-e5e5-e5e5-e5e5e5e5e5e5', '34444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-05 17:15:00'),
       ('f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6', '34444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-05 17:30:00'),
       ('a0a0a0a0-a0a0-a0a0-a0a0-a0a0a0a0a0a0', '34444444-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-07-05 17:45:00'),
       ('b0b0b0b0-b0b0-b0b0-b0b0-b0b0b0b0b0b0', '34444444-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-07-05 18:00:00');

-- EVENTO 10 (38888888...) - 12 Presentes
INSERT INTO registrations (user_id, event_id, attended, notified, registration_date)
VALUES ('c0c0c0c0-c0c0-c0c0-c0c0-c0c0c0c0c0c0', '38888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-01 09:00:00'),
       ('d0d0d0d0-d0d0-d0d0-d0d0-d0d0d0d0d0d0', '38888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-01 09:10:00'),
       ('e0e0e0e0-e0e0-e0e0-e0e0-e0e0e0e0e0e0', '38888888-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-08-01 09:20:00'),
       ('f0f0f0f0-f0f0-f0f0-f0f0-f0f0f0f0f0f0', '38888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-01 09:30:00'),
       ('a1b1c1d1-a1b1-c1d1-a1b1-c1d1a1b1c1d1', '38888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-01 09:40:00'),
       ('a2b2c2d2-a2b2-c2d2-a2b2-c2d2a2b2c2d2', '38888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-01 09:50:00'),
       ('a3b3c3d3-a3b3-c3d3-a3b3-c3d3a3b3c3d3', '38888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-01 10:00:00'),
       ('a4b4c4d4-a4b4-c4d4-a4b4-c4d4a4b4c4d4', '38888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-01 10:10:00'),
       ('a5b5c5d5-a5b5-c5d5-a5b5-c5d5a5b5c5d5', '38888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-01 10:20:00'),
       ('a6b6c6d6-a6b6-c6d6-a6b6-c6d6a6b6c6d6', '38888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-01 10:30:00'),
       ('a7b7c7d7-a7b7-c7d7-a7b7-c7d7a7b7c7d7', '38888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-01 10:40:00'),
       ('a8b8c8d8-a8b8-c8d8-a8b8-c8d8a8b8c8d8', '38888888-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-01 10:50:00');

-- EVENTO 11 (43333333...) - 11 Presentes
INSERT INTO registrations (user_id, event_id, attended, notified, registration_date)
VALUES ('a9b9c9d9-a9b9-c9d9-a9b9-c9d9a9b9c9d9', '43333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-10 14:00:00'),
       ('ad111111-1111-1111-1111-111111111111', '43333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-10 14:10:00'),
       ('ad222222-2222-2222-2222-222222222222', '43333333-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-08-10 14:20:00'),
       ('ad333333-3333-3333-3333-333333333333', '43333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-10 14:30:00'),
       ('ad444444-4444-4444-4444-444444444444', '43333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-10 14:40:00'),
       ('ad555555-5555-5555-5555-555555555555', '43333333-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-08-10 14:50:00'),
       ('f7d2e9b8-31a4-4c5d-92e1-8b0f7a63c294', '43333333-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-08-10 15:00:00'),
       ('be89dede-00f2-48eb-880b-c9b728ce5bfc', '43333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-10 15:10:00'),
       ('b82120cf-41a7-406a-b52d-259cdbef3041', '43333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-10 15:20:00'),
       ('5c0a92a1-b445-4e4b-807c-6fbca67b9092', '43333333-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-08-10 15:30:00'),
       ('9be3d05c-7638-4f78-814a-ce4c21463262', '43333333-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-08-10 15:40:00');
-- EVENTO 12 (47777777...) - 19
INSERT INTO registrations (user_id, event_id, attended, notified, registration_date)
VALUES ('f7d2e9b8-31a4-4c5d-92e1-8b0f7a63c294', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 08:00:00'),
       ('be89dede-00f2-48eb-880b-c9b728ce5bfc', '47777777-d628-46ef-b838-b66d4758b966', FALSE, TRUE,
        '2024-05-01 08:05:00'),
       ('b82120cf-41a7-406a-b52d-259cdbef3041', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 08:10:00'),
       ('5c0a92a1-b445-4e4b-807c-6fbca67b9092', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 08:15:00'),
       ('9be3d05c-7638-4f78-814a-ce4c21463262', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 08:20:00'),
       ('286c2d18-9814-4d88-a55d-14bacaefcf49', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 08:25:00'),
       ('073b9076-2317-4511-a9c3-535654e75363', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 08:30:00'),
       ('be4999bf-6d31-4414-a0a6-ae61d53a6387', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 08:35:00'),
       ('54307ac7-8117-42c3-abc2-a74b112979c3', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 08:40:00'),
       ('e6137fdc-6fc2-4776-8616-9e238c1b48a7', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 08:45:00'),
       ('11111111-1111-1111-1111-111111111111', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 08:50:00'),
       ('22222222-2222-2222-2222-222222222222', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 08:55:00'),
       ('33333333-3333-3333-3333-333333333333', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 09:00:00'),
       ('44444444-4444-4444-4444-444444444444', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 09:05:00'),
       ('55555555-5555-5555-5555-555555555555', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 09:10:00'),
       ('66666666-6666-6666-6666-666666666666', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 09:15:00'),
       ('77777777-7777-7777-7777-777777777777', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 09:20:00'),
       ('88888888-8888-8888-8888-888888888888', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 09:25:00'),
       ('99999999-9999-9999-9999-999999999999', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 09:30:00'),
       ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '47777777-d628-46ef-b838-b66d4758b966', TRUE, TRUE,
        '2024-05-01 09:35:00');

INSERT INTO certificates (user_id, event_id, validation_code, issued_at)
VALUES
-- Evento E999...
('11111111-1111-1111-1111-111111111111', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-1111-E999', NOW()),
('22222222-2222-2222-2222-222222222222', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-2222-E999', NOW()),
('33333333-3333-3333-3333-333333333333', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-3333-E999', NOW()),
('44444444-4444-4444-4444-444444444444', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-4444-E999', NOW()),
('55555555-5555-5555-5555-555555555555', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-5555-E999', NOW()),
('66666666-6666-6666-6666-666666666666', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-6666-E999', NOW()),
('77777777-7777-7777-7777-777777777777', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-7777-E999', NOW()),
('88888888-8888-8888-8888-888888888888', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-8888-E999', NOW()),
('99999999-9999-9999-9999-999999999999', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-9999-E999', NOW()),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-AAAA-E999', NOW()),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-BBBB-E999', NOW()),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-CCCC-E999', NOW()),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-DDDD-E999', NOW()),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-EEEE-E999', NOW()),
('ffffffff-ffff-ffff-ffff-ffffffffffff', 'e9999999-d628-46ef-b838-b66d4758b966', 'VAL-FFFF-E999', NOW()),

-- Evento F111...
('40404040-4040-4040-4040-404040404040', 'f1111111-d628-46ef-b838-b66d4758b966', 'VAL-4040-F111', NOW()),
('50505050-5050-5050-5050-505050505050', 'f1111111-d628-46ef-b838-b66d4758b966', 'VAL-5050-F111', NOW()),
('60606060-6060-6060-6060-606060606060', 'f1111111-d628-46ef-b838-b66d4758b966', 'VAL-6060-F111', NOW()),
('70707070-7070-7070-7070-707070707070', 'f1111111-d628-46ef-b838-b66d4758b966', 'VAL-7070-F111', NOW()),
('80808080-8080-8080-8080-808080808080', 'f1111111-d628-46ef-b838-b66d4758b966', 'VAL-8080-F111', NOW()),
('90909090-9090-9090-9090-909090909090', 'f1111111-d628-46ef-b838-b66d4758b966', 'VAL-9090-F111', NOW()),
('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', 'f1111111-d628-46ef-b838-b66d4758b966', 'VAL-A1A1-F111', NOW()),
('b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2', 'f1111111-d628-46ef-b838-b66d4758b966', 'VAL-B2B2-F111', NOW()),
('c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3', 'f1111111-d628-46ef-b838-b66d4758b966', 'VAL-C3C3-F111', NOW()),
('d4d4d4d4-d4d4-d4d4-d4d4-d4d4d4d4d4d4', 'f1111111-d628-46ef-b838-b66d4758b966', 'VAL-D4D4-F111', NOW()),
('e5e5e5e5-e5e5-e5e5-e5e5-e5e5e5e5e5e5', 'f1111111-d628-46ef-b838-b66d4758b966', 'VAL-E5E5-F111', NOW()),
('f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6', 'f1111111-d628-46ef-b838-b66d4758b966', 'VAL-F6F6-F111', NOW()),

-- Evento F666...
('d0d0d0d0-d0d0-d0d0-d0d0-d0d0d0d0d0d0', 'f6666666-d628-46ef-b838-b66d4758b966', 'VAL-D0D0-F666', NOW()),
('e0e0e0e0-e0e0-e0e0-e0e0-e0e0e0e0e0e0', 'f6666666-d628-46ef-b838-b66d4758b966', 'VAL-E0E0-F666', NOW()),
('f0f0f0f0-f0f0-f0f0-f0f0-f0f0f0f0f0f0', 'f6666666-d628-46ef-b838-b66d4758b966', 'VAL-F0F0-F666', NOW()),
('a3b3c3d3-a3b3-c3d3-a3b3-c3d3a3b3c3d3', 'f6666666-d628-46ef-b838-b66d4758b966', 'VAL-A3B3-F666', NOW()),
('a5b5c5d5-a5b5-c5d5-a5b5-c5d5a5b5c5d5', 'f6666666-d628-46ef-b838-b66d4758b966', 'VAL-A5B5-F666', NOW()),
('a7b7c7d7-a7b7-c7d7-a7b7-c7d7a7b7c7d7', 'f6666666-d628-46ef-b838-b66d4758b966', 'VAL-A7B7-F666', NOW()),
('a9b9c9d9-a9b9-c9d9-a9b9-c9d9a9b9c9d9', 'f6666666-d628-46ef-b838-b66d4758b966', 'VAL-A9B9-F666', NOW()),
('ad111111-1111-1111-1111-111111111111', 'f6666666-d628-46ef-b838-b66d4758b966', 'VAL-AD11-F666', NOW()),

-- Evento F999...
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'f9999999-d628-46ef-b838-b66d4758b966', 'VAL-BBBB-F999', NOW()),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'f9999999-d628-46ef-b838-b66d4758b966', 'VAL-CCCC-F999', NOW()),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'f9999999-d628-46ef-b838-b66d4758b966', 'VAL-DDDD-F999', NOW()),
('ffffffff-ffff-ffff-ffff-ffffffffffff', 'f9999999-d628-46ef-b838-b66d4758b966', 'VAL-FFFF-F999', NOW()),
('10101010-1010-1010-1010-101010101010', 'f9999999-d628-46ef-b838-b66d4758b966', 'VAL-1010-F999', NOW()),
('20202020-2020-2020-2020-202020202020', 'f9999999-d628-46ef-b838-b66d4758b966', 'VAL-2020-F999', NOW()),
('30303030-3030-3030-3030-303030303030', 'f9999999-d628-46ef-b838-b66d4758b966', 'VAL-3030-F999', NOW()),
('50505050-5050-5050-5050-505050505050', 'f9999999-d628-46ef-b838-b66d4758b966', 'VAL-5050-F999', NOW()),
('60606060-6060-6060-6060-606060606060', 'f9999999-d628-46ef-b838-b66d4758b966', 'VAL-6060-F999', NOW()),
('70707070-7070-7070-7070-707070707070', 'f9999999-d628-46ef-b838-b66d4758b966', 'VAL-7070-F999', NOW()),
('80808080-8080-8080-8080-808080808080', 'f9999999-d628-46ef-b838-b66d4758b966', 'VAL-8080-F999', NOW()),

-- Evento 1444...
('f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6', '14444444-d628-46ef-b838-b66d4758b966', 'VAL-F6F6-1444', NOW()),
('a0a0a0a0-a0a0-a0a0-a0a0-a0a0a0a0a0a0', '14444444-d628-46ef-b838-b66d4758b966', 'VAL-A0A0-1444', NOW()),
('b0b0b0b0-b0b0-b0b0-b0b0-b0b0b0b0b0b0', '14444444-d628-46ef-b838-b66d4758b966', 'VAL-B0B0-1444', NOW()),
('c0c0c0c0-c0c0-c0c0-c0c0-c0c0c0c0c0c0', '14444444-d628-46ef-b838-b66d4758b966', 'VAL-C0C0-1444', NOW()),
('d0d0d0d0-d0d0-d0d0-d0d0-d0d0d0d0d0d0', '14444444-d628-46ef-b838-b66d4758b966', 'VAL-D0D0-1444', NOW()),
('e0e0e0e0-e0e0-e0e0-e0e0-e0e0e0e0e0e0', '14444444-d628-46ef-b838-b66d4758b966', 'VAL-E0E0-1444', NOW()),
('f0f0f0f0-f0f0-f0f0-f0f0-f0f0f0f0f0f0', '14444444-d628-46ef-b838-b66d4758b966', 'VAL-F0F0-1444', NOW()),
('a1b1c1d1-a1b1-c1d1-a1b1-c1d1a1b1c1d1', '14444444-d628-46ef-b838-b66d4758b966', 'VAL-A1B1-1444', NOW()),
('a2b2c2d2-a2b2-c2d2-a2b2-c2d2a2b2c2d2', '14444444-d628-46ef-b838-b66d4758b966', 'VAL-A2B2-1444', NOW()),

-- Evento 1888...
('a5b5c5d5-a5b5-c5d5-a5b5-c5d5a5b5c5d5', '18888888-d628-46ef-b838-b66d4758b966', 'VAL-A5B5-1888', NOW()),
('a6b6c6d6-a6b6-c6d6-a6b6-c6d6a6b6c6d6', '18888888-d628-46ef-b838-b66d4758b966', 'VAL-A6B6-1888', NOW()),
('a7b7c7d7-a7b7-c7d7-a7b7-c7d7a7b7c7d7', '18888888-d628-46ef-b838-b66d4758b966', 'VAL-A7B7-1888', NOW()),
('a8b8c8d8-a8b8-c8d8-a8b8-c8d8a8b8c8d8', '18888888-d628-46ef-b838-b66d4758b966', 'VAL-A8B8-1888', NOW()),
('a9b9c9d9-a9b9-c9d9-a9b9-c9d9a9b9c9d9', '18888888-d628-46ef-b838-b66d4758b966', 'VAL-A9B9-1888', NOW()),
('ad111111-1111-1111-1111-111111111111', '18888888-d628-46ef-b838-b66d4758b966', 'VAL-AD11-1888', NOW()),
('ad222222-2222-2222-2222-222222222222', '18888888-d628-46ef-b838-b66d4758b966', 'VAL-AD22-1888', NOW()),
('ad333333-3333-3333-3333-333333333333', '18888888-d628-46ef-b838-b66d4758b966', 'VAL-AD33-1888', NOW()),
('ad444444-4444-4444-4444-444444444444', '18888888-d628-46ef-b838-b66d4758b966', 'VAL-AD44-1888', NOW()),
('ad555555-5555-5555-5555-555555555555', '18888888-d628-46ef-b838-b66d4758b966', 'VAL-AD55-1888', NOW()),
('f7d2e9b8-31a4-4c5d-92e1-8b0f7a63c294', '18888888-d628-46ef-b838-b66d4758b966', 'VAL-F7D2-1888', NOW()),
('be89dede-00f2-48eb-880b-c9b728ce5bfc', '18888888-d628-46ef-b838-b66d4758b966', 'VAL-BE89-1888', NOW()),
('5c0a92a1-b445-4e4b-807c-6fbca67b9092', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-5C0A-2333', NOW()),
('9be3d05c-7638-4f78-814a-ce4c21463262', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-9BE3-2333', NOW()),
('286c2d18-9814-4d88-a55d-14bacaefcf49', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-286C-2333', NOW()),
('073b9076-2317-4511-a9c3-535654e75363', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-073B-2333', NOW()),
('be4999bf-6d31-4414-a0a6-ae61d53a6387', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-BE49-2333', NOW()),
('54307ac7-8117-42c3-abc2-a74b112979c3', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-5430-2333', NOW()),
('e6137fdc-6fc2-4776-8616-9e238c1b48a7', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-E613-2333', NOW()),
('11111111-1111-1111-1111-111111111111', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-1111-2333', NOW()),
('22222222-2222-2222-2222-222222222222', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-2222-2333', NOW()),
('33333333-3333-3333-3333-333333333333', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-3333-2333', NOW()),
('44444444-4444-4444-4444-444444444444', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-4444-2333', NOW()),
('55555555-5555-5555-5555-555555555555', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-5555-2333', NOW()),
('66666666-6666-6666-6666-666666666666', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-6666-2333', NOW()),
('77777777-7777-7777-7777-777777777777', '23333333-d628-46ef-b838-b66d4758b966', 'VAL-7777-2333', NOW()),

-- Evento 2777...
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '27777777-d628-46ef-b838-b66d4758b966', 'VAL-EEEE-2777', NOW()),
('ffffffff-ffff-ffff-ffff-ffffffffffff', '27777777-d628-46ef-b838-b66d4758b966', 'VAL-FFFF-2777', NOW()),
('10101010-1010-1010-1010-101010101010', '27777777-d628-46ef-b838-b66d4758b966', 'VAL-1010-2777', NOW()),
('20202020-2020-2020-2020-202020202020', '27777777-d628-46ef-b838-b66d4758b966', 'VAL-2020-2777', NOW()),
('30303030-3030-3030-3030-303030303030', '27777777-d628-46ef-b838-b66d4758b966', 'VAL-3030-2777', NOW()),
('40404040-4040-4040-4040-404040404040', '27777777-d628-46ef-b838-b66d4758b966', 'VAL-4040-2777', NOW()),

-- Evento 3444...
('60606060-6060-6060-6060-606060606060', '34444444-d628-46ef-b838-b66d4758b966', 'VAL-6060-3444', NOW()),
('70707070-7070-7070-7070-707070707070', '34444444-d628-46ef-b838-b66d4758b966', 'VAL-7070-3444', NOW()),
('80808080-8080-8080-8080-808080808080', '34444444-d628-46ef-b838-b66d4758b966', 'VAL-8080-3444', NOW()),
('90909090-9090-9090-9090-909090909090', '34444444-d628-46ef-b838-b66d4758b966', 'VAL-9090-3444', NOW()),
('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', '34444444-d628-46ef-b838-b66d4758b966', 'VAL-A1A1-3444', NOW()),
('b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2', '34444444-d628-46ef-b838-b66d4758b966', 'VAL-B2B2-3444', NOW()),
('c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3', '34444444-d628-46ef-b838-b66d4758b966', 'VAL-C3C3-3444', NOW()),
('e5e5e5e5-e5e5-e5e5-e5e5-e5e5e5e5e5e5', '34444444-d628-46ef-b838-b66d4758b966', 'VAL-E5E5-3444', NOW()),
('f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6', '34444444-d628-46ef-b838-b66d4758b966', 'VAL-F6F6-3444', NOW()),
('a0a0a0a0-a0a0-a0a0-a0a0-a0a0a0a0a0a0', '34444444-d628-46ef-b838-b66d4758b966', 'VAL-A0A0-3444', NOW()),

-- Evento 3888...
('c0c0c0c0-c0c0-c0c0-c0c0-c0c0c0c0c0c0', '38888888-d628-46ef-b838-b66d4758b966', 'VAL-C0C0-3888', NOW()),
('d0d0d0d0-d0d0-d0d0-d0d0-d0d0d0d0d0d0', '38888888-d628-46ef-b838-b66d4758b966', 'VAL-D0D0-3888', NOW()),
('f0f0f0f0-f0f0-f0f0-f0f0-f0f0f0f0f0f0', '38888888-d628-46ef-b838-b66d4758b966', 'VAL-F0F0-3888', NOW()),
('a1b1c1d1-a1b1-c1d1-a1b1-c1d1a1b1c1d1', '38888888-d628-46ef-b838-b66d4758b966', 'VAL-A1B1-3888', NOW()),
('a2b2c2d2-a2b2-c2d2-a2b2-c2d2a2b2c2d2', '38888888-d628-46ef-b838-b66d4758b966', 'VAL-A2B2-3888', NOW()),
('a3b3c3d3-a3b3-c3d3-a3b3-c3d3a3b3c3d3', '38888888-d628-46ef-b838-b66d4758b966', 'VAL-A3B3-3888', NOW()),
('a4b4c4d4-a4b4-c4d4-a4b4-c4d4a4b4c4d4', '38888888-d628-46ef-b838-b66d4758b966', 'VAL-A4B4-3888', NOW()),
('a5b5c5d5-a5b5-c5d5-a5b5-c5d5a5b5c5d5', '38888888-d628-46ef-b838-b66d4758b966', 'VAL-A5B5-3888', NOW()),
('a6b6c6d6-a6b6-c6d6-a6b6-c6d6a6b6c6d6', '38888888-d628-46ef-b838-b66d4758b966', 'VAL-A6B6-3888', NOW()),
('a7b7c7d7-a7b7-c7d7-a7b7-c7d7a7b7c7d7', '38888888-d628-46ef-b838-b66d4758b966', 'VAL-A7B7-3888', NOW()),
('a8b8c8d8-a8b8-c8d8-a8b8-c8d8a8b8c8d8', '38888888-d628-46ef-b838-b66d4758b966', 'VAL-A8B8-3888', NOW()),

-- Evento 4333...
('a9b9c9d9-a9b9-c9d9-a9b9-c9d9a9b9c9d9', '43333333-d628-46ef-b838-b66d4758b966', 'VAL-A9B9-4333', NOW()),
('ad111111-1111-1111-1111-111111111111', '43333333-d628-46ef-b838-b66d4758b966', 'VAL-AD11-4333', NOW()),
('ad333333-3333-3333-3333-333333333333', '43333333-d628-46ef-b838-b66d4758b966', 'VAL-AD33-4333', NOW()),
('ad444444-4444-4444-4444-444444444444', '43333333-d628-46ef-b838-b66d4758b966', 'VAL-AD44-4333', NOW()),
('be89dede-00f2-48eb-880b-c9b728ce5bfc', '43333333-d628-46ef-b838-b66d4758b966', 'VAL-BE89-4333', NOW()),
('b82120cf-41a7-406a-b52d-259cdbef3041', '43333333-d628-46ef-b838-b66d4758b966', 'VAL-B821-4333', NOW()),
('9be3d05c-7638-4f78-814a-ce4c21463262', '43333333-d628-46ef-b838-b66d4758b966', 'VAL-9BE3-4333', NOW()),

-- Evento 4777...
('f7d2e9b8-31a4-4c5d-92e1-8b0f7a63c294', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-F7D2-4777', NOW()),
('b82120cf-41a7-406a-b52d-259cdbef3041', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-B821-4777', NOW()),
('5c0a92a1-b445-4e4b-807c-6fbca67b9092', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-5C0A-4777', NOW()),
('9be3d05c-7638-4f78-814a-ce4c21463262', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-9BE3-4777', NOW()),
('286c2d18-9814-4d88-a55d-14bacaefcf49', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-286C-4777', NOW()),
('073b9076-2317-4511-a9c3-535654e75363', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-073B-4777', NOW()),
('be4999bf-6d31-4414-a0a6-ae61d53a6387', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-BE49-4777', NOW()),
('54307ac7-8117-42c3-abc2-a74b112979c3', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-5430-4777', NOW()),
('e6137fdc-6fc2-4776-8616-9e238c1b48a7', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-E613-4777', NOW()),
('11111111-1111-1111-1111-111111111111', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-1111-4777', NOW()),
('22222222-2222-2222-2222-222222222222', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-2222-4777', NOW()),
('33333333-3333-3333-3333-333333333333', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-3333-4777', NOW()),
('44444444-4444-4444-4444-444444444444', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-4444-4777', NOW()),
('55555555-5555-5555-5555-555555555555', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-5555-4777', NOW()),
('66666666-6666-6666-6666-666666666666', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-6666-4777', NOW()),
('77777777-7777-7777-7777-777777777777', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-7777-4777', NOW()),
('88888888-8888-8888-8888-888888888888', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-8888-4777', NOW()),
('99999999-9999-9999-9999-999999999999', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-9999-4777', NOW()),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '47777777-d628-46ef-b838-b66d4758b966', 'VAL-AAAA-4777', NOW());


INSERT INTO evaluations (registration_id, rating, comment)
SELECT r.id,
       rating,
       CASE rating
           WHEN 1 THEN 'Péssimo, organização deixou a desejar.'
           WHEN 2 THEN 'Regular, esperava mais do conteúdo.'
           WHEN 3 THEN 'Bom, mas pode melhorar a infraestrutura.'
           WHEN 4 THEN 'Muito bom! Palestras bem focadas.'
           WHEN 5 THEN 'Excelente! Melhor evento da vida.'
           END
FROM (
         SELECT id,
                floor(random() * 5 + 1)::int AS rating
         FROM registrations
     ) r
    ON CONFLICT (registration_id) DO NOTHING;


INSERT INTO organizer_members (user_id, organizer_id)
VALUES
-- Bloco de usuários variados
('be89dede-00f2-48eb-880b-c9b728ce5bfc', 'a1111111-1111-1111-1111-111111111111'),
('b82120cf-41a7-406a-b52d-259cdbef3041', 'a2222222-2222-2222-2222-222222222222'),
('5c0a92a1-b445-4e4b-807c-6fbca67b9092', 'a3333333-3333-3333-3333-333333333333'),
('9be3d05c-7638-4f78-814a-ce4c21463262', 'a4444444-4444-4444-4444-444444444444'),
('286c2d18-9814-4d88-a55d-14bacaefcf49', 'a5555555-5555-5555-5555-555555555555'),
('073b9076-2317-4511-a9c3-535654e75363', 'a6666666-6666-6666-6666-666666666666'),
('be4999bf-6d31-4414-a0a6-ae61d53a6387', 'a7777777-7777-7777-7777-777777777777'),
('54307ac7-8117-42c3-abc2-a74b112979c3', 'a8888888-8888-8888-8888-888888888888'),
('e6137fdc-6fc2-4776-8616-9e238c1b48a7', 'a9999999-9999-9999-9999-999999999999'),

-- Sequência 111... até fff...
('11111111-1111-1111-1111-111111111111', 'b1111111-1111-1111-1111-111111111111'),
('11111111-1111-1111-1111-111111111111', 'b2222222-2222-2222-2222-222222222222'), -- 2 orgs
('22222222-2222-2222-2222-222222222222', 'b3333333-3333-3333-3333-333333333333'),
('33333333-3333-3333-3333-333333333333', 'b4444444-4444-4444-4444-444444444444'),
('44444444-4444-4444-4444-444444444444', 'b5555555-5555-5555-5555-555555555555'),
('55555555-5555-5555-5555-555555555555', 'b6666666-6666-6666-6666-666666666666'),
('55555555-5555-5555-5555-555555555555', 'b7777777-7777-7777-7777-777777777777'), -- 2 orgs
('66666666-6666-6666-6666-666666666666', 'b8888888-8888-8888-8888-888888888888'),
('77777777-7777-7777-7777-777777777777', 'b9999999-9999-9999-9999-999999999999'),
('88888888-8888-8888-8888-888888888888', 'c1111111-1111-1111-1111-111111111111'),
('99999999-9999-9999-9999-999999999999', 'c2222222-2222-2222-2222-222222222222'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'c3333333-3333-3333-3333-333333333333'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'c4444444-4444-4444-4444-444444444444'), -- 2 orgs
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'c5555555-5555-5555-5555-555555555555'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'c6666666-6666-6666-6666-666666666666'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'c7777777-7777-7777-7777-777777777777'),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'c8888888-8888-8888-8888-888888888888'),
('ffffffff-ffff-ffff-ffff-ffffffffffff', 'c9999999-9999-9999-9999-999999999999'),
('ffffffff-ffff-ffff-ffff-ffffffffffff', 'd1111111-1111-1111-1111-111111111111') -- 2 orgs
ON CONFLICT (organizer_id, user_id) DO NOTHING;

CREATE OR REPLACE FUNCTION notify_organizer_request_update()
RETURNS TRIGGER AS $$
DECLARE
nome_org VARCHAR;
BEGIN
    -- se o status foi alterado e não é mais PENDING
    IF OLD.status = 'PENDING' AND NEW.status IN ('APPROVED', 'REJECTED') THEN

        -- o nome da organização para deixar a notificação mais rica
SELECT name INTO nome_org FROM organizers WHERE id = NEW.organizer_id;

-- insere a notificação automática para o usuário
INSERT INTO notifications (user_id, type, title, message, status, created_at)
VALUES (
           NEW.user_id,
           NEW.status, -- Usa o próprio status ('APPROVED' ou 'REJECTED') como tipo da notificação
           'Atualização de Solicitação',
           'Sua solicitação para ingressar na organização "' || nome_org || '" foi ' ||
           CASE
               WHEN NEW.status = 'APPROVED' THEN 'APROVADA.'
               ELSE 'REJEITADA.'
               END,
           FALSE, -- status false = Notificação não lida
           NOW()
       );
END IF;

RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- cria o trigger que escuta a tabela
CREATE TRIGGER trg_notify_org_request
    AFTER UPDATE ON organizer_requests
    FOR EACH ROW
    EXECUTE FUNCTION notify_organizer_request_update();