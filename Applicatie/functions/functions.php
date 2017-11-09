<?php

function getBalies() {


        $db = connectDatabase();

        $balies = [];

        try {
            $stmt = $db->prepare(
                'SELECT *
                FROM Balie'
            );
            $stmt->execute([

            ]);

            while ($row = $stmt->fetch()) {
                $balies += $row;
            }
        } catch (PDOException $e) {
            http_response_code(500);
            die();
        }
    }
?>